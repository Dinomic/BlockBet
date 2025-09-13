package com.dinomic.blockbet.entities;

import com.dinomic.blockbet.enums.TransactionType;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;

@Entity
@Table(name = "TRANSACTION_RECEIPTS")
@AllArgsConstructor
public class BBTransactionReceipt {
    @SequenceGenerator(name = "SEQ_TRANSACTION_RECEIPTS", sequenceName = "SEQ_TRANSACTION_RECEIPTS", allocationSize = 1)
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "SEQ_TRANSACTION_RECEIPTS")
    @Column(name = "TRANSACTION_RECEIPT_ID", nullable = false)
    @Id
    private Long transactionReceiptId;

    @Column(name = "TRANSACTION_TYPE", nullable = false)
    @Enumerated(EnumType.STRING)
    private TransactionType transactionType;

    @Column(name = "HASH", nullable = false)
    private String hash;

    @Column(name = "FROM_ADDRESS", nullable = false)
    private String fromAddress;

    @Column(name = "TO_ADDRESS", nullable = false)
    private String toAddress;

    @Column(name = "BLOCK_HASH")
    private String blockHash;

    @Column(name = "BLOCK_NUMBER")
    private Integer blockNumber;

    @Column(name = "GAS_USED")
    private Integer gasUsed;

    @Column(name = "EFFECTIVE_GAS_PRICE")
    private Integer effectiveGasPrice;

    @Column(name = "IS_SUCCESS")
    private Boolean isSuccess;

    public BBTransactionReceipt() {

    }

    public Long getTransactionReceiptId() {
        return transactionReceiptId;
    }

    public void setTransactionReceiptId(Long transactionReceiptId) {
        this.transactionReceiptId = transactionReceiptId;
    }

    public TransactionType getTransactionType() {
        return transactionType;
    }

    public void setTransactionType(TransactionType transactionType) {
        this.transactionType = transactionType;
    }

    public String getHash() {
        return hash;
    }

    public void setHash(String hash) {
        this.hash = hash;
    }

    public String getFromAddress() {
        return fromAddress;
    }

    public void setFromAddress(String fromAddress) {
        this.fromAddress = fromAddress;
    }

    public String getToAddress() {
        return toAddress;
    }

    public void setToAddress(String toAddress) {
        this.toAddress = toAddress;
    }

    public String getBlockHash() {
        return blockHash;
    }

    public void setBlockHash(String blockHash) {
        this.blockHash = blockHash;
    }

    public Integer getBlockNumber() {
        return blockNumber;
    }

    public void setBlockNumber(Integer blockNumber) {
        this.blockNumber = blockNumber;
    }

    public Integer getGasUsed() {
        return gasUsed;
    }

    public void setGasUsed(Integer gasUsed) {
        this.gasUsed = gasUsed;
    }

    public Integer getEffectiveGasPrice() {
        return effectiveGasPrice;
    }

    public void setEffectiveGasPrice(Integer effectiveGasPrice) {
        this.effectiveGasPrice = effectiveGasPrice;
    }

    public Boolean getSuccess() {
        return isSuccess;
    }

    public void setSuccess(Boolean success) {
        isSuccess = success;
    }
}
