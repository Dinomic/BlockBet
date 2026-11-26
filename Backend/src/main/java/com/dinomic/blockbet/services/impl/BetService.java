package com.dinomic.blockbet.services.impl;

import blockbet.openapi.model.BetContractType;
import blockbet.openapi.model.BetOption;
import com.dinomic.blockbet.daos.Account;
import com.dinomic.blockbet.daos.BBTransactionReceipt;
import com.dinomic.blockbet.daos.Bet;
import com.dinomic.blockbet.daos.Wallet;
import com.dinomic.blockbet.enums.TransactionType;
import com.dinomic.blockbet.exceptions.BlockBetError;
import com.dinomic.blockbet.exceptions.BlockBetException;
import com.dinomic.blockbet.repositories.IBetRepo;
import com.dinomic.blockbet.repositories.IWalletRepo;
import com.dinomic.blockbet.services.IBetContractService;
import com.dinomic.blockbet.services.IBetService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.web3j.protocol.core.methods.response.TransactionReceipt;
import org.web3j.utils.Numeric;

import java.math.BigInteger;
import java.util.regex.Pattern;

/** Lookups shared by {@link BlockBetService}, {@link BookieService}, {@link BettorService} and {@link InternalService}. */
@Service
public class BetService implements IBetService {
    private static final Pattern ADDRESS_PATTERN = Pattern.compile("^0x[0-9a-fA-F]{40}$");

    @Autowired
    IBetRepo betRepo;

    @Autowired
    IWalletRepo walletRepo;

    @Override
    public Bet findBet(BigInteger betId) {
        if (betId == null || betId.bitLength() > 62) {
            throw new BlockBetException(BlockBetError.BET_NOT_FOUND, "Bet not found");
        }
        return betRepo.findById(betId.longValue()).orElseThrow(() ->
            new BlockBetException(BlockBetError.BET_NOT_FOUND, "Bet not found"));
    }

    @Override
    public Bet findBet(BigInteger betId, BetContractType type) {
        Bet bet = findBet(betId);
        if (bet.getContract().getContractType() != type) {
            throw new BlockBetException(BlockBetError.BET_NOT_FOUND, "Bet not found");
        }
        return bet;
    }

    @Override
    public Wallet lockOwnWallet(Account account, String address) {
        if (address == null || !ADDRESS_PATTERN.matcher(address).matches()) {
            throw new BlockBetException(BlockBetError.INVALID_REQUEST, "fromAddress is not a valid wallet address");
        }
        return walletRepo.findByAccountAndAddressForUpdate(account, address).orElseThrow(() ->
            new BlockBetException(BlockBetError.WALLET_NOT_FOUND, "Wallet not found with associated account"));
    }

    @Override
    public BBTransactionReceipt newReceipt(TransactionType type, TransactionReceipt receipt, String from, String to,
                                           BigInteger amount, boolean success) {
        BBTransactionReceipt result = new BBTransactionReceipt();
        result.setTransactionType(type);
        result.setHash(receipt.getTransactionHash());
        result.setFromAddress(from);
        result.setToAddress(to);
        result.setBlockHash(receipt.getBlockHash());
        result.setBlockNumber(receipt.getBlockNumber().intValue());
        result.setGasUsed(receipt.getGasUsed().intValue());
        result.setEffectiveGasPrice(Numeric.decodeQuantity(receipt.getEffectiveGasPrice()).intValue());
        result.setAmount(amount);
        result.setSuccess(success);
        return result;
    }

    @Override
    public IBetContractService.ChainOption toContractOption(BetOption option) {
        return switch (option) {
            case A -> IBetContractService.ChainOption.A;
            case B -> IBetContractService.ChainOption.B;
            case C -> IBetContractService.ChainOption.C;
            case D -> IBetContractService.ChainOption.D;
            case E -> IBetContractService.ChainOption.E;
        };
    }
}
