package com.dinomic.BlockBet.repositories.customRepo;

import com.dinomic.BlockBet.entities.BBTransactionReceipt;

import java.math.BigInteger;
import java.util.List;

public interface IBBTransactionReceiptCustomRepo {

    List<BBTransactionReceipt> getBBTransactionReceipts(BigInteger offset, BigInteger limit);

}
