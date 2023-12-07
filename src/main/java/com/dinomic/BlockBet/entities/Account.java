package com.dinomic.BlockBet.entities;


import jakarta.persistence.*;

import java.util.Set;


@Entity
@Table(name = "ACCOUNTS")
public class Account {

    @SequenceGenerator(name = "SEQ_ACCOUNTS", sequenceName = "SEQ_ACCOUNTS", allocationSize = 1)
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "SEQ_ACCOUNTS")
    @Column(name = "ACCOUNT_ID", nullable = false)
    @Id
    private Long accountId;

    @Column(name = "ACCOUNT_NAME", nullable = false)
    private String username;

    @Column(name = "ACCOUNT_PASSWORD", nullable = false)
    private String password;

    @Column(name = "EMAIL", nullable = false)
    private String email;

    @Column(name = "ENABLED", nullable = false)
    private Boolean isEnabled = true;

    @OneToMany(cascade = CascadeType.ALL, mappedBy = "account", fetch = FetchType.LAZY)
    private Set<Authority> authorities;

    @OneToOne(cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    @JoinColumn(name = "ACCOUNT_DETAIL_ID")
    private AccountDetail accountDetail;
//
//    @OneToMany(cascade = {CascadeType.PERSIST, CascadeType.MERGE, CascadeType.DETACH, CascadeType.REFRESH}
//            , mappedBy = "account", fetch = FetchType.LAZY)
//    private List<Wallet> wallets;

    public Account(){

    }

    public Long getAccountId() {
        return accountId;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public Boolean getEnabled() {
        return isEnabled;
    }

    public void setEnabled(Boolean enabled) {
        isEnabled = enabled;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public Set<Authority> getAuthorities() {
        return authorities;
    }

    public void setAuthorities(Set<Authority> authorities) {
        this.authorities = authorities;
    }

    //    public Collection<? extends GrantedAuthority> getAuthorities() {
//        return this.authorities.stream()
//                .map(role -> new SimpleGrantedAuthority(role.getName().name())).collect(Collectors.toList());
//    }
//
//    public void setAuthorities(Set<Authority> authorities) {
//        this.authorities = authorities;
//    }

    public AccountDetail getAccountDetail() {
        return accountDetail;
    }

    public void setAccountDetail(AccountDetail accountDetail) {
        this.accountDetail = accountDetail;
    }
//
//    public List<Wallet> getWallets() {
//        return wallets;
//    }
//
//    public void setWallets(List<Wallet> wallets) {
//        this.wallets = wallets;
//    }
}

