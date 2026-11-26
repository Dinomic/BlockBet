package com.dinomic.blockbet.daos;

import jakarta.persistence.*;

import java.time.LocalDateTime;

/** Records that an account has placed its one bet on a bet. */
@Entity
@Table(name = "BET_PARTICIPANTS")
public class BetParticipant {
    @SequenceGenerator(name = "SEQ_BET_PARTICIPANTS", sequenceName = "SEQ_BET_PARTICIPANTS", allocationSize = 1)
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "SEQ_BET_PARTICIPANTS")
    @Column(name = "BET_PARTICIPANT_ID", nullable = false)
    @Id
    private Long betParticipantId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "BET_ID", nullable = false)
    private Bet bet;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ACCOUNT_ID", nullable = false)
    private Account account;

    @Column(name = "WALLET_ADDRESS", nullable = false)
    private String walletAddress;

    @Column(name = "BET_OPTION", nullable = false)
    private String option;

    @Column(name = "TX_HASH", nullable = false)
    private String txHash;

    @Column(name = "CREATED_AT", nullable = false, insertable = false, updatable = false)
    private LocalDateTime createdAt;

    public BetParticipant() {
    }

    public Bet getBet() {
        return bet;
    }

    public void setBet(Bet bet) {
        this.bet = bet;
    }

    public Account getAccount() {
        return account;
    }

    public void setAccount(Account account) {
        this.account = account;
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

    public String getTxHash() {
        return txHash;
    }

    public void setTxHash(String txHash) {
        this.txHash = txHash;
    }
}
