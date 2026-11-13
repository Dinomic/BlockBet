package com.dinomic.blockbet.services.impl;

import com.dinomic.blockbet.daos.BBTransactionReceipt;
import com.dinomic.blockbet.enums.TransactionType;
import com.dinomic.blockbet.repositories.IBBTransactionReceiptRepo;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/**
 * Writes transfer records in their <b>own</b> transactions. A transfer's record must be durable
 * <i>before</i> the transaction is broadcast: if it only lived in the caller's transaction, a failed
 * commit after a successful broadcast would leave tokens moved on chain with no record.
 * (A separate bean, so the {@code REQUIRES_NEW} proxy is actually applied.)
 */
@Component
public class TransferReceiptRecorder {

    @Autowired
    IBBTransactionReceiptRepo receiptRepo;

    /**
     * Records a transfer that is about to be broadcast (outcome unknown: IS_SUCCESS stays null).
     * The column itself stays nullable: faucet funding rows have no client key.
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void recordPending(String hash, String fromAddress, String toAddress, String idempotencyKey) {
        BBTransactionReceipt receipt = new BBTransactionReceipt();
        receipt.setHash(hash);
        receipt.setFromAddress(fromAddress);
        receipt.setToAddress(toAddress);
        receipt.setTransactionType(TransactionType.TOKEN_TRANSFER);
        receipt.setIdempotencyKey(idempotencyKey);
        receiptRepo.saveAndFlush(receipt);
    }

    /** The transfer is known not to be on chain (rejected / never sent): free its idempotency key. */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void markFailed(String hash) {
        receiptRepo.findByHash(hash).ifPresent(r -> {
            r.markFailed();
            receiptRepo.saveAndFlush(r);
        });
    }
}
