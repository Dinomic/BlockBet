package com.dinomic.BlockBet.enums;

public enum Role {
    ROLE_BETTOR("BETTOR"),
    ROLE_BOOKIE("BOOKIE");

    private String role;

    Role(String role) {
        this.role = role;
    }

    public String getRole() {
        return role;
    }
}
