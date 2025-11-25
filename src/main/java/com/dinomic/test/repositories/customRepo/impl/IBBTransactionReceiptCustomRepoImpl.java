package com.dinomic.blockbet.repositories.customRepo.impl;

import com.dinomic.blockbet.entities.BBTransactionReceipt;
import com.dinomic.blockbet.repositories.customRepo.IBBTransactionReceiptCustomRepo;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.TypedQuery;

import java.math.BigInteger;
import java.util.List;

public class IBBTransactionReceiptCustomRepoImpl implements IBBTransactionReceiptCustomRepo {

    @PersistenceContext
    EntityManager entityManager;

    @Override
    public List<BBTransactionReceipt> getBBTransactionReceipts(BigInteger offset, BigInteger limit) {

        String query = "select * from TRANSACTION_RECEIPTS";

        return entityManager.createNativeQuery(query, BBTransactionReceipt.class).getResultList();
    }

//
//
//    Query query = entityManager.createNativeQuery(queryStr.toString(), Tuple.class);
//
//    setNativeQueryParamsIfNotNull(query, mapParams);
//
//    List<Tuple> applicationDtos = query.getResultList();
//
//
//        if (applicationDtos.isEmpty()) {
//        return new ArrayList<>();
//    }
//        return applicationDtos.stream().map(tuple ->
//            new ApplicationDto(
//            bigIntegerToLong((BigInteger) tuple.get("applicationId")),
//            (String) tuple.get("mobileApplicationId")
//            )
//            ).collect(Collectors.toList());
}
