package com.dinomic.blockbet.repositories;

import com.dinomic.blockbet.daos.BBTransactionReceipt;
import com.dinomic.blockbet.enums.TransactionType;
import jakarta.validation.constraints.NotNull;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
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

    Optional<BBTransactionReceipt> findByFromAddressAndIdempotencyKey(@NotNull String fromAddress, @NotNull String idempotencyKey);

    /** Receipts sent from or to any of the given addresses (exact match), newest first. */
    @Query(
        value = "select * from TRANSACTION_RECEIPTS tr " +
            "where tr.FROM_ADDRESS in (:addresses) or tr.TO_ADDRESS in (:addresses) " +
            "order by tr.TRANSACTION_RECEIPT_ID desc " +
            "offset :offset limit :limit",
        nativeQuery = true
    )
    List<BBTransactionReceipt> findByAddresses(@Param("addresses") List<String> addresses,
                                               @Param("offset") long offset,
                                               @Param("limit") long limit);

    @Query(
        value = "select count(*) from TRANSACTION_RECEIPTS tr " +
            "where tr.FROM_ADDRESS in (:addresses) or tr.TO_ADDRESS in (:addresses)",
        nativeQuery = true
    )
    long countByAddresses(@Param("addresses") List<String> addresses);

    /** Transfers that were broadcast but whose outcome is not known yet (IS_SUCCESS is null). */
    @Query("select r from BBTransactionReceipt r where r.transactionType = :type and r.isSuccess is null " +
        "order by r.transactionReceiptId")
    List<BBTransactionReceipt> findUnconfirmed(@Param("type") TransactionType type, Pageable pageable);
}