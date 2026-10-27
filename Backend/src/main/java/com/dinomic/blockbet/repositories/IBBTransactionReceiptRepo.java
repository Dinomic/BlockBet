package com.dinomic.blockbet.repositories;

import com.dinomic.blockbet.daos.BBTransactionReceipt;
import jakarta.validation.constraints.NotNull;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.math.BigInteger;
import java.util.List;
import java.util.Optional;

@Repository
public interface IBBTransactionReceiptRepo extends JpaRepository<BBTransactionReceipt, Long> {

    @Query(
        value = "select * from TRANSACTION_RECEIPTS tr " +
            "where tr.IS_SUCCESS = false " +
            "order by TRANSACTION_RECEIPT_ID " +
            "offset :offset limit :limit ",
        nativeQuery = true
    )
    List<BBTransactionReceipt> getUnDoneTxReceipts(@NotNull BigInteger offset, @NotNull BigInteger limit);


    Optional<BBTransactionReceipt> findByHash (@NotNull String hash);
}