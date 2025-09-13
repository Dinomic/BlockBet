package com.dinomic.blockbet.entities;

import jakarta.persistence.*;

@Entity
@Table(name = "WALLETS")
public class Wallet {
    @SequenceGenerator(name = "SEQ_WALLETS", sequenceName = "SEQ_WALLETS", allocationSize = 1)
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "SEQ_WALLETS")
    @Column(name = "WALLET_ID", nullable = false)
    @Id
    private Long walletId;

    @Column(name = "ADDRESS", nullable = false)
    private String address;

    @Column(name = "PUBLIC_KEY", nullable = false)
    private String publicKey;

    @Column(name = "PRIVATE_KEY", nullable = false)
    private String privateKey;

    @ManyToOne(cascade = {CascadeType.PERSIST, CascadeType.MERGE, CascadeType.DETACH, CascadeType.REFRESH},
            fetch = FetchType.LAZY)
    @JoinColumn(name="ACCOUNT_ID", nullable=false)
    private Account account;

    public Wallet() {

    }

    public Long getWalletId() {
        return walletId;
    }

    public String getAddress() {
        return address;
    }

    public void setAddress(String address) {
        this.address = address;
    }

    public String getPublicKey() {
        return publicKey;
    }

    public void setPublicKey(String publicKey) {
        this.publicKey = publicKey;
    }

    public String getPrivateKey() {
        return privateKey;
    }

    public void setPrivateKey(String privateKey) {
        this.privateKey = privateKey;
    }

    public Account getAccount() {
        return account;
    }

    public void setAccount(Account account) {
        this.account = account;
    }
}
