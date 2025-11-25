package com.dinomic.blockbet.repositories.customRepo;

import com.dinomic.blockbet.entities.BBTransactionReceipt;

import java.math.BigInteger;
import java.util.List;

public interface IBBTransactionReceiptCustomRepo {

    List<BBTransactionReceipt> getBBTransactionReceipts(BigInteger offset, BigInteger limit);

}
