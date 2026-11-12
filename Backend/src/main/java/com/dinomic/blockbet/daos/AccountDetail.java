package com.dinomic.blockbet.daos;

import com.dinomic.blockbet.enums.Gender;
import jakarta.persistence.*;

import java.time.LocalDate;

@Entity
@Table(name = "ACCOUNT_DETAILS")
public class AccountDetail {
    @SequenceGenerator(name = "SEQ_ACCOUNT_DETAILS", sequenceName = "SEQ_ACCOUNT_DETAILS", allocationSize = 1)
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "SEQ_ACCOUNT_DETAILS")
    @Column(name = "ACCOUNT_DETAIL_ID", nullable = false)
    @Id
    private Long accountDetailId;

    @Column(name = "PHONE", length = 16)
    private String phone;

    @Column(name = "ADDRESS")
    private String address;

    @Column(name = "NATIONALITY", length = 2)
    private String nationality;

    @Column(name = "DATE_OF_BIRTH")
    private LocalDate dateOfBirth;

    @Enumerated(EnumType.STRING)
    @Column(name = "GENDER", length = 16)
    private Gender gender;

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

    public LocalDate getDateOfBirth() {
        return dateOfBirth;
    }

    public void setDateOfBirth(LocalDate dateOfBirth) {
        this.dateOfBirth = dateOfBirth;
    }

    public Gender getGender() {
        return gender;
    }

    public void setGender(Gender gender) {
        this.gender = gender;
    }

    public Account getAccount() {
        return account;
    }

    public void setAccount(Account account) {
        this.account = account;
    }
}
