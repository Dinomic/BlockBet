package com.dinomic.blockbet.enums;

public enum AccountRole {
    ROLE_BETTOR("BETTOR"),
    ROLE_BOOKIE("BOOKIE");

    private String role;

    AccountRole(String role) {
        this.role = role;
    }

    public String getRole() {
        return role;
    }
}
