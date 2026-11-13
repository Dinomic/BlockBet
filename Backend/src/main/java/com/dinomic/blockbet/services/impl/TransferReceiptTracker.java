package com.dinomic.blockbet.services.impl;

import com.dinomic.blockbet.daos.BBTransactionReceipt;
import com.dinomic.blockbet.enums.TransactionType;
import com.dinomic.blockbet.repositories.IBBTransactionReceiptRepo;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.PageRequest;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import org.web3j.protocol.Web3j;
import org.web3j.protocol.core.methods.response.TransactionReceipt;
import org.web3j.utils.Numeric;

import java.math.BigInteger;
import java.util.List;
import java.util.Optional;

/**
 * Completes transfer records after the fact: a transfer is stored as "pending" when it is broadcast,
 * and this job fills in block, gas and the final outcome once the chain has mined it.
 */
@Component
public class TransferReceiptTracker {
    private static final Logger log = LoggerFactory.getLogger(TransferReceiptTracker.class);
    private static final int BATCH_SIZE = 50;

    @Autowired
    IBBTransactionReceiptRepo receiptRepo;

    @Autowired
    Web3j web3j;

    @Scheduled(fixedDelayString = "${blockbet.receipt-tracker.interval-ms:5000}")
    @Transactional
    public void confirmPendingTransfers() {
        List<BBTransactionReceipt> pending =
            receiptRepo.findUnconfirmed(TransactionType.TOKEN_TRANSFER, PageRequest.of(0, BATCH_SIZE));

        for (BBTransactionReceipt record : pending) {
            try {
                Optional<TransactionReceipt> onChain =
                    web3j.ethGetTransactionReceipt(record.getHash()).send().getTransactionReceipt();
                onChain.ifPresent(receipt -> apply(record, receipt));
            } catch (Exception e) {
                // Node unreachable or a bad answer: leave the record pending and try again next tick.
                log.warn("Could not check transaction {}: {}", record.getHash(), e.getMessage());
                return;
            }
        }
    }

    private void apply(BBTransactionReceipt record, TransactionReceipt receipt) {
        record.setBlockHash(receipt.getBlockHash());
        record.setBlockNumber(clampToInt(receipt.getBlockNumber()));
        record.setGasUsed(clampToInt(receipt.getGasUsed()));
        if (receipt.getEffectiveGasPrice() != null) {
            record.setEffectiveGasPrice(clampToInt(Numeric.decodeQuantity(receipt.getEffectiveGasPrice())));
        }
        if (receipt.isStatusOK()) {
            record.setSuccess(true);
        } else {
            record.markFailed();
        }
        receiptRepo.save(record);
    }

    /** The receipt columns are INT; a value that does not fit is stored as the maximum instead of wrapping. */
    private static Integer clampToInt(BigInteger value) {
        if (value == null) {
            return null;
        }
        return value.bitLength() < 32 ? value.intValue() : Integer.MAX_VALUE;
    }
}
