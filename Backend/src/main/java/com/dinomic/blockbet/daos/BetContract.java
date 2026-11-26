package com.dinomic.blockbet.daos;

import blockbet.openapi.model.BetContractType;
import jakarta.persistence.*;

import java.time.LocalDateTime;

/** A deployed instance of the BlockBet smart contract. */
@Entity
@Table(name = "BET_CONTRACTS")
public class BetContract {
    @SequenceGenerator(name = "SEQ_BET_CONTRACTS", sequenceName = "SEQ_BET_CONTRACTS", allocationSize = 1)
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "SEQ_BET_CONTRACTS")
    @Column(name = "BET_CONTRACT_ID", nullable = false)
    @Id
    private Long betContractId;

    @Column(name = "ADDRESS", nullable = false)
    private String address;

    @Enumerated(EnumType.STRING)
    @Column(name = "CONTRACT_TYPE", nullable = false)
    private BetContractType contractType;

    @Column(name = "CODE_HASH", nullable = false)
    private String codeHash;

    @Column(name = "DEPLOY_TX_HASH", nullable = false)
    private String deployTxHash;

    @Column(name = "DEPLOYED_AT", nullable = false, insertable = false, updatable = false)
    private LocalDateTime deployedAt;

    public BetContract() {
    }

    public Long getBetContractId() {
        return betContractId;
    }

    public String getAddress() {
        return address;
    }

    public void setAddress(String address) {
        this.address = address;
    }

    public BetContractType getContractType() {
        return contractType;
    }

    public void setContractType(BetContractType contractType) {
        this.contractType = contractType;
    }

    public String getCodeHash() {
        return codeHash;
    }

    public void setCodeHash(String codeHash) {
        this.codeHash = codeHash;
    }

    public String getDeployTxHash() {
        return deployTxHash;
    }

    public void setDeployTxHash(String deployTxHash) {
        this.deployTxHash = deployTxHash;
    }

    public LocalDateTime getDeployedAt() {
        return deployedAt;
    }
}
