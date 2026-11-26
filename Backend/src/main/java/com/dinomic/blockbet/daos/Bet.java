package com.dinomic.blockbet.daos;

import jakarta.persistence.*;

import java.time.LocalDateTime;

/** Off-chain description of a bet. Rules and money live in the smart contract (see chainBetId). */
@Entity
@Table(name = "BETS")
public class Bet {
    @SequenceGenerator(name = "SEQ_BETS", sequenceName = "SEQ_BETS", allocationSize = 1)
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "SEQ_BETS")
    @Column(name = "BET_ID", nullable = false)
    @Id
    private Long betId;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "BET_CONTRACT_ID", nullable = false)
    private BetContract contract;

    @Column(name = "CHAIN_BET_ID", nullable = false)
    private Long chainBetId;

    @Column(name = "TITLE", nullable = false)
    private String title;

    @Column(name = "DESCRIPTION")
    private String description;

    @Column(name = "IMAGE_URL")
    private String imageUrl;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "BOOKIE_WALLET_ID", nullable = false)
    private Wallet bookieWallet;

    @Column(name = "CREATE_TX_HASH", nullable = false)
    private String createTxHash;

    @Column(name = "CREATED_AT", nullable = false, insertable = false, updatable = false)
    private LocalDateTime createdAt;

    /** Copy of the close time stored in the contract, in UTC. Null for bets created before it was stored. */
    @Column(name = "CLOSE_TIME")
    private LocalDateTime closeTime;

    /** Off-chain flag for the internal team: the bookie has not resolved this bet for too long. */
    @Column(name = "CAUTION", nullable = false)
    private boolean caution;

    /** Set when the caution check has looked at this bet after its deadline. */
    @Column(name = "CAUTION_CHECKED_AT")
    private LocalDateTime cautionCheckedAt;

    public Bet() {
    }

    public LocalDateTime getCloseTime() {
        return closeTime;
    }

    public void setCloseTime(LocalDateTime closeTime) {
        this.closeTime = closeTime;
    }

    public boolean isCaution() {
        return caution;
    }

    public void setCaution(boolean caution) {
        this.caution = caution;
    }

    public LocalDateTime getCautionCheckedAt() {
        return cautionCheckedAt;
    }

    public void setCautionCheckedAt(LocalDateTime cautionCheckedAt) {
        this.cautionCheckedAt = cautionCheckedAt;
    }

    public Long getBetId() {
        return betId;
    }

    public BetContract getContract() {
        return contract;
    }

    public void setContract(BetContract contract) {
        this.contract = contract;
    }

    public Long getChainBetId() {
        return chainBetId;
    }

    public void setChainBetId(Long chainBetId) {
        this.chainBetId = chainBetId;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }

    public Wallet getBookieWallet() {
        return bookieWallet;
    }

    public void setBookieWallet(Wallet bookieWallet) {
        this.bookieWallet = bookieWallet;
    }

    public String getCreateTxHash() {
        return createTxHash;
    }

    public void setCreateTxHash(String createTxHash) {
        this.createTxHash = createTxHash;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
}
