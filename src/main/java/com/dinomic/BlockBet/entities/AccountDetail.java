package com.dinomic.BlockBet.entities;


import jakarta.persistence.*;

@Entity
@Table(name = "ACCOUNT_DETAILS")
public class AccountDetail {
    @SequenceGenerator(name = "SEQ_ACCOUNT_DETAILS", sequenceName = "SEQ_ACCOUNT_DETAILS", allocationSize = 1)
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "SEQ_ACCOUNT_DETAILS")
    @Column(name = "ACCOUNT_DETAIL_ID", nullable = false)
    @Id
    private Long accountDetailId;

    @Column(name = "PHONE", length = 16, nullable = false)
    private String phone;

    @Column(name = "ADDRESS", nullable = false)
    private String address;

    @Column(name = "NATIONALITY", length = 2, nullable = false)
    private String nationality;

    @OneToOne(mappedBy = "accountDetail")
    private Account account;

    public Long getAccountDetailId() {
        return accountDetailId;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public String getAddress() {
        return address;
    }

    public void setAddress(String address) {
        this.address = address;
    }

    public String getNationality() {
        return nationality;
    }

    public void setNationality(String nationality) {
        this.nationality = nationality;
    }

    public Account getAccount() {
        return account;
    }

    public void setAccount(Account account) {
        this.account = account;
    }
}
