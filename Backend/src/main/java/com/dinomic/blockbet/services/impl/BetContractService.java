package com.dinomic.blockbet.services.impl;

import blockbet.openapi.model.BetContractType;
import com.dinomic.blockbet.config.BlockchainProperties;
import com.dinomic.blockbet.daos.BetContract;
import com.dinomic.blockbet.daos.Wallet;
import com.dinomic.blockbet.exceptions.BlockBetError;
import com.dinomic.blockbet.exceptions.BlockBetException;
import com.dinomic.blockbet.repositories.IBetContractRepo;
import com.dinomic.blockbet.services.IBetContractService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionDefinition;
import org.springframework.transaction.support.TransactionTemplate;
import org.web3j.abi.EventEncoder;
import org.web3j.abi.FunctionEncoder;
import org.web3j.abi.FunctionReturnDecoder;
import org.web3j.abi.TypeReference;
import org.web3j.abi.datatypes.Address;
import org.web3j.abi.datatypes.Bool;
import org.web3j.abi.datatypes.DynamicArray;
import org.web3j.abi.datatypes.Event;
import org.web3j.abi.datatypes.Function;
import org.web3j.abi.datatypes.Type;
import org.web3j.abi.datatypes.Utf8String;
import org.web3j.abi.datatypes.generated.Uint256;
import org.web3j.abi.datatypes.generated.Uint8;
import org.web3j.crypto.Credentials;
import org.web3j.crypto.Hash;
import org.web3j.protocol.Web3j;
import org.web3j.protocol.core.DefaultBlockParameterName;
import org.web3j.protocol.core.methods.request.Transaction;
import org.web3j.protocol.core.methods.response.EthCall;
import org.web3j.protocol.core.methods.response.EthEstimateGas;
import org.web3j.protocol.core.methods.response.EthSendTransaction;
import org.web3j.protocol.core.methods.response.Log;
import org.web3j.protocol.core.methods.response.TransactionReceipt;
import org.web3j.tx.RawTransactionManager;
import org.web3j.tx.response.PollingTransactionReceiptProcessor;
import org.web3j.utils.Numeric;

import java.io.IOException;
import java.math.BigInteger;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class BetContractService implements IBetContractService, ApplicationRunner {
    private static final Logger log = LoggerFactory.getLogger(BetContractService.class);

    /**
     * Compiled contract of each type (produced from its .sol file, see the header of that file). A new
     * BetContractType needs an entry here and, if its ABI differs, its own methods in this service.
     */
    private static final Map<BetContractType, String> BIN_RESOURCES = new EnumMap<>(Map.of(
        BetContractType.MULTIPLE_OPTION_SIMPLE_POOL, "contracts/simple/BlockBetSimplePool.bin"));
    private static final String REVERT_PREFIX = "execution reverted";
    private static final long RECEIPT_POLL_MS = 1000;
    private static final int RECEIPT_POLL_ATTEMPTS = 60;

    private static final Event BET_CREATED = new Event("BetCreated", Arrays.asList(
        new TypeReference<Uint256>(true) {
        },
        new TypeReference<Address>(true) {
        },
        new TypeReference<Uint256>() {
        },
        new TypeReference<Uint256>() {
        }));

    private static final Event INTERNAL_PAYOUT = new Event("InternalPayout", Arrays.asList(
        new TypeReference<Uint256>(true) {
        },
        new TypeReference<Address>(true) {
        },
        new TypeReference<Uint256>() {
        }));

    private static final Event PAYOUT = new Event("Payout", Arrays.asList(
        new TypeReference<Uint256>(true) {
        },
        new TypeReference<Address>(true) {
        },
        new TypeReference<Uint256>() {
        },
        new TypeReference<Bool>() {
        }));

    @Autowired
    BlockchainProperties blockchainProperties;

    @Autowired
    Web3j web3j;

    @Autowired
    IBetContractRepo betContractRepo;

    @Autowired
    PlatformTransactionManager transactionManager;

    private final Map<BetContractType, BetContract> current = new ConcurrentHashMap<>();

    /** Deploys every type at startup so the first request does not have to. A failure must not stop the app. */
    @Override
    public void run(ApplicationArguments args) {
        for (BetContractType type : BetContractType.values()) {
            try {
                BetContract contract = currentContract(type);
                log.info("{} contract at {}", type, contract.getAddress());
            } catch (RuntimeException e) {
                log.warn("{} contract is not available, betting on it is disabled until it is: {}", type, e.getMessage());
            }
        }
    }

    /**
     * Not transactional on purpose: the deployment is on chain once it is mined, so its row must be committed
     * on its own and not rolled back with some later failure of the caller.
     */
    @Override
    public synchronized BetContract currentContract(BetContractType type) {
        if (type == null) {
            throw new BlockBetException(BlockBetError.INVALID_REQUEST, "contractType is required");
        }
        BetContract cached = current.get(type);
        if (cached != null) {
            return cached;
        }

        String bin = loadBin(type);
        String codeHash = Hash.sha3String(bin);

        BetContract contract = betContractRepo.findByCodeHash(codeHash).orElseGet(() -> deploy(type, bin, codeHash));
        current.put(type, contract);
        return contract;
    }

    /** Saved in its own transaction even when a request's transaction is open, see {@link #currentContract}. */
    private BetContract saveInNewTransaction(BetContract contract) {
        TransactionTemplate template = new TransactionTemplate(transactionManager);
        template.setPropagationBehavior(TransactionDefinition.PROPAGATION_REQUIRES_NEW);
        return template.execute(status -> betContractRepo.save(contract));
    }

    private BetContract deploy(BetContractType type, String bin, String codeHash) {
        Credentials deployer = Credentials.create(blockchainProperties.mainAccount().privateKey());
        TransactionReceipt receipt = send(deployer, "", bin, BigInteger.ZERO);

        BetContract contract = new BetContract();
        contract.setContractType(type);
        contract.setAddress(receipt.getContractAddress().toLowerCase());
        contract.setCodeHash(codeHash);
        contract.setDeployTxHash(receipt.getTransactionHash());
        log.info("Deployed {} contract at {} (tx {})", type, contract.getAddress(), contract.getDeployTxHash());
        return saveInNewTransaction(contract);
    }

    private String loadBin(BetContractType type) {
        String resourcePath = BIN_RESOURCES.get(type);
        if (resourcePath == null) {
            throw new BlockBetException(BlockBetError.INVALID_REQUEST, "Unsupported contractType " + type);
        }
        ClassPathResource resource = new ClassPathResource(resourcePath);
        if (!resource.exists()) {
            throw new BlockBetException(BlockBetError.BLOCKCHAIN_ERROR,
                "The " + type + " contract is not compiled: " + resourcePath + " is missing");
        }
        try {
            String bin = new String(resource.getInputStream().readAllBytes(), StandardCharsets.UTF_8).trim();
            return Numeric.prependHexPrefix(bin);
        } catch (IOException e) {
            throw new BlockBetException(BlockBetError.BLOCKCHAIN_ERROR, "Cannot read " + resourcePath);
        }
    }

    /** The internal account is blockchain.mainAccount, which also deploys the contracts. */
    @Override
    public String internalAccountAddress() {
        return Credentials.create(blockchainProperties.mainAccount().privateKey()).getAddress().toLowerCase();
    }

    @Override
    public CreatedBet createBet(Wallet bookie, BetContract contract, List<String> optionNames,
                                BigInteger stakeWei, BigInteger durationSeconds) {
        List<Utf8String> names = optionNames.stream().map(Utf8String::new).toList();
        Function function = new Function("createBet",
            Arrays.asList(new DynamicArray<>(Utf8String.class, names),
                new Uint256(stakeWei), new Uint256(durationSeconds)),
            List.of());

        TransactionReceipt receipt = send(Credentials.create(bookie.getPrivateKey()), contract.getAddress(),
            FunctionEncoder.encode(function), BigInteger.ZERO);

        String createdTopic = EventEncoder.encode(BET_CREATED);
        for (Log eventLog : receipt.getLogs()) {
            if (contract.getAddress().equalsIgnoreCase(eventLog.getAddress())
                && !eventLog.getTopics().isEmpty() && createdTopic.equals(eventLog.getTopics().get(0))) {
                long chainBetId = Numeric.toBigInt(eventLog.getTopics().get(1)).longValueExact();
                return new CreatedBet(chainBetId, receipt.getTransactionHash());
            }
        }
        // The bet exists on chain but we cannot tell its id; keep the hash so it can be recovered by hand.
        log.error("createBet tx {} succeeded but has no BetCreated event", receipt.getTransactionHash());
        throw new BlockBetException(BlockBetError.BLOCKCHAIN_ERROR, "Could not read the created bet from the chain");
    }

    @Override
    public TransactionReceipt placeBet(Wallet bettor, BetContract contract, long chainBetId, ChainOption option,
                                       BigInteger stakeWei) {
        Function function = new Function("placeBet",
            Arrays.asList(new Uint256(chainBetId), new Uint8(option.toChain())), List.of());

        return send(Credentials.create(bettor.getPrivateKey()), contract.getAddress(),
            FunctionEncoder.encode(function), stakeWei);
    }

    @Override
    public ResolvedBet resolve(Wallet bookie, BetContract contract, long chainBetId, ChainOption winner) {
        Function function = new Function("resolve",
            Arrays.asList(new Uint256(chainBetId), new Uint8(winner.toChain())), List.of());

        TransactionReceipt receipt = send(Credentials.create(bookie.getPrivateKey()), contract.getAddress(),
            FunctionEncoder.encode(function), BigInteger.ZERO);

        BigInteger internalPayout = BigInteger.ZERO;
        String payoutTopic = EventEncoder.encode(INTERNAL_PAYOUT);
        for (Log eventLog : receipt.getLogs()) {
            if (contract.getAddress().equalsIgnoreCase(eventLog.getAddress())
                && !eventLog.getTopics().isEmpty() && payoutTopic.equals(eventLog.getTopics().get(0))) {
                internalPayout = internalPayout.add(Numeric.toBigInt(eventLog.getData()));
            }
        }
        return new ResolvedBet(receipt, internalPayout, parsePayouts(receipt.getLogs(), contract.getAddress()));
    }

    /** The Payout events the contract emitted in a resolve transaction, one per winner. */
    static List<WinnerPayout> parsePayouts(List<Log> logs, String contractAddress) {
        String payoutTopic = EventEncoder.encode(PAYOUT);
        List<WinnerPayout> payouts = new ArrayList<>();
        for (Log eventLog : logs) {
            if (!contractAddress.equalsIgnoreCase(eventLog.getAddress())
                || eventLog.getTopics().size() < 3 || !payoutTopic.equals(eventLog.getTopics().get(0))) {
                continue;
            }
            String to = ((Address) FunctionReturnDecoder.decodeIndexedValue(
                eventLog.getTopics().get(2), new TypeReference<Address>() {
                })).getValue();
            List<Type> data = FunctionReturnDecoder.decode(eventLog.getData(), PAYOUT.getNonIndexedParameters());
            payouts.add(new WinnerPayout(to.toLowerCase(), (BigInteger) data.get(0).getValue(), (Boolean) data.get(1).getValue()));
        }
        return payouts;
    }

    @Override
    public String refundExpired(BetContract contract, long chainBetId) {
        Function function = new Function("refundExpired", List.of(new Uint256(chainBetId)), List.of());

        return send(Credentials.create(blockchainProperties.mainAccount().privateKey()), contract.getAddress(),
            FunctionEncoder.encode(function), BigInteger.ZERO).getTransactionHash();
    }

    @Override
    public ChainBet getBet(BetContract contract, long chainBetId) {
        List<Type> market = call(contract, "getMarket", chainBetId, Arrays.asList(
            new TypeReference<Address>() {
            },
            new TypeReference<DynamicArray<Utf8String>>() {
            },
            new TypeReference<Uint256>() {
            },
            new TypeReference<Uint256>() {
            }));
        List<Type> state = call(contract, "getState", chainBetId, Arrays.asList(
            new TypeReference<Uint8>() {
            },
            new TypeReference<Uint8>() {
            },
            new TypeReference<DynamicArray<Uint256>>() {
            }));

        @SuppressWarnings("unchecked")
        List<Utf8String> names = ((DynamicArray<Utf8String>) market.get(1)).getValue();
        @SuppressWarnings("unchecked")
        List<Uint256> counts = ((DynamicArray<Uint256>) state.get(2)).getValue();

        return new ChainBet(
            (String) market.get(0).getValue(),
            names.stream().map(Utf8String::getValue).toList(),
            (BigInteger) market.get(2).getValue(),
            (BigInteger) market.get(3).getValue(),
            ChainStatus.fromChain((BigInteger) state.get(0).getValue()),
            ChainOption.fromChain((BigInteger) state.get(1).getValue()),
            counts.stream().map(Uint256::getValue).toList());
    }

    private List<Type> call(BetContract contract, String name, long chainBetId, List<TypeReference<?>> outputs) {
        Function function = new Function(name, List.of(new Uint256(chainBetId)), outputs);
        try {
            EthCall response = web3j.ethCall(
                Transaction.createEthCallTransaction(null, contract.getAddress(), FunctionEncoder.encode(function)),
                DefaultBlockParameterName.LATEST).send();
            if (response.hasError()) {
                throw revertOrChainError(response.getError().getMessage());
            }
            return FunctionReturnDecoder.decode(response.getValue(), function.getOutputParameters());
        } catch (IOException e) {
            log.error("Could not read {}({}) from the contract", name, chainBetId, e);
            throw new BlockBetException(BlockBetError.BLOCKCHAIN_ERROR, "Could not reach the blockchain node");
        }
    }

    /**
     * Estimates gas first (this runs the call, so a revert such as "Betting closed" comes back as a readable
     * 4xx before anything is sent), then sends and waits for the receipt.
     * Callers must serialize sends per wallet: the nonce is read from the node.
     */
    private TransactionReceipt send(Credentials credentials, String to, String data, BigInteger value) {
        String from = credentials.getAddress();
        try {
            BigInteger gasPrice = web3j.ethGasPrice().send().getGasPrice();

            EthEstimateGas estimate = web3j.ethEstimateGas(new Transaction(
                from, null, null, null, to.isEmpty() ? null : to, value, data)).send();
            if (estimate.hasError()) {
                throw revertOrChainError(estimate.getError().getMessage());
            }
            BigInteger gasLimit = estimate.getAmountUsed().multiply(BigInteger.valueOf(12)).divide(BigInteger.TEN);

            BigInteger needed = value.add(gasPrice.multiply(gasLimit));
            BigInteger balance = web3j.ethGetBalance(from, DefaultBlockParameterName.LATEST).send().getBalance();
            if (balance.compareTo(needed) < 0) {
                throw new BlockBetException(BlockBetError.INSUFFICIENT_BALANCE,
                    "Insufficient balance: the wallet must cover the stake plus the network fee");
            }

            RawTransactionManager txManager = new RawTransactionManager(
                web3j, credentials, blockchainProperties.network().chainId());
            EthSendTransaction sent = txManager.sendTransaction(gasPrice, gasLimit, to, data, value);
            if (sent.hasError()) {
                log.warn("Node rejected the transaction from {}: {}", from, sent.getError().getMessage());
                throw new BlockBetException(BlockBetError.BLOCKCHAIN_ERROR, "The network rejected the transaction");
            }
            TransactionReceipt receipt = new PollingTransactionReceiptProcessor(web3j, RECEIPT_POLL_MS, RECEIPT_POLL_ATTEMPTS)
                .waitForTransactionReceipt(sent.getTransactionHash());

            if (!receipt.isStatusOK()) {
                log.warn("Tx {} from {} to {} reverted on chain", receipt.getTransactionHash(), from, to);
                throw new BlockBetException(BlockBetError.BET_REJECTED, "The transaction was reverted by the contract");
            }
            return receipt;
        } catch (BlockBetException e) {
            throw e;
        } catch (Exception e) {
            // Includes a receipt timeout: the tx may still be mined later, so say so instead of "failed".
            log.error("Contract transaction from {} to {} failed", from, to, e);
            throw new BlockBetException(BlockBetError.BLOCKCHAIN_ERROR,
                "The blockchain did not confirm the transaction in time. Check the bet before retrying");
        }
    }

    private static BlockBetException revertOrChainError(String nodeMessage) {
        if (nodeMessage != null && nodeMessage.startsWith(REVERT_PREFIX)) {
            String reason = nodeMessage.substring(REVERT_PREFIX.length()).replaceFirst("^:\\s*", "");
            return new BlockBetException(BlockBetError.BET_REJECTED, reason.isEmpty() ? "Rejected by the contract" : reason);
        }
        log.error("Node error: {}", nodeMessage);
        return new BlockBetException(BlockBetError.BLOCKCHAIN_ERROR, "The blockchain node rejected the request");
    }
}
