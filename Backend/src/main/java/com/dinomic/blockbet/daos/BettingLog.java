package com.dinomic.blockbet.daos;

import com.dinomic.blockbet.enums.BettingAction;
import jakarta.persistence.*;

import java.math.BigInteger;
import java.time.LocalDateTime;

/** One betting action (see {@link BettingAction}). The ids are plain columns, not relations: see the migration. */
@Entity
@Table(name = "BETTING_LOG")
public class BettingLog {
    @SequenceGenerator(name = "SEQ_BETTING_LOG", sequenceName = "SEQ_BETTING_LOG", allocationSize = 1)
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "SEQ_BETTING_LOG")
    @Column(name = "BETTING_LOG_ID", nullable = false)
    @Id
    private Long bettingLogId;

    @Column(name = "BET_ID")
    private Long betId;

    @Enumerated(EnumType.STRING)
    @Column(name = "ACTION", nullable = false)
    private BettingAction action;

    @Column(name = "ACCOUNT_ID")
    private Long accountId;

    @Column(name = "WALLET_ADDRESS")
    private String walletAddress;

    @Column(name = "BET_OPTION")
    private String option;

    @Column(name = "AMOUNT")
    private BigInteger amount;

    @Column(name = "TX_HASH")
    private String txHash;

    @Column(name = "DETAIL")
    private String detail;

    @Column(name = "CREATED_AT", nullable = false, insertable = false, updatable = false)
    private LocalDateTime createdAt;

    public BettingLog() {
    }

    public Long getBettingLogId() {
        return bettingLogId;
    }

    public Long getBetId() {
        return betId;
    }

    public void setBetId(Long betId) {
        this.betId = betId;
    }

    public BettingAction getAction() {
        return action;
    }

    public void setAction(BettingAction action) {
        this.action = action;
    }

    public Long getAccountId() {
        return accountId;
    }

    public void setAccountId(Long accountId) {
        this.accountId = accountId;
    }

    public String getWalletAddress() {
        return walletAddress;
    }

    public void setWalletAddress(String walletAddress) {
        this.walletAddress = walletAddress;
    }

    public String getOption() {
        return option;
    }

    public void setOption(String option) {
        this.option = option;
    }

    public BigInteger getAmount() {
        return amount;
    }

    public void setAmount(BigInteger amount) {
        this.amount = amount;
    }

    public String getTxHash() {
        return txHash;
    }

    public void setTxHash(String txHash) {
        this.txHash = txHash;
    }

    public String getDetail() {
        return detail;
    }

    public void setDetail(String detail) {
        this.detail = detail;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
}