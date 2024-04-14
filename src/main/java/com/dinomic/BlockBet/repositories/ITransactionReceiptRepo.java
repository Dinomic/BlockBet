package com.dinomic.BlockBet.repositories;

import com.dinomic.BlockBet.entities.BBTransactionReceipt;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import javax.validation.constraints.NotNull;
import java.math.BigInteger;
import java.util.List;
import java.util.Optional;

@Repository
public interface ITransactionReceiptRepo extends JpaRepository<BBTransactionReceipt, Long> {

    @Query(
            value = "select * from TRANSACTION_RECEIPTS tr " +
                    "where tr.IS_DONE = false " +
                    "order by TRANSACTION_RECEIPT_ID " +
                    "offset :offset limit :limit ",
            nativeQuery = true
    )
    List<BBTransactionReceipt> getUnDoneTxReceipts(@NotNull BigInteger offset, @NotNull BigInteger limit);


    Optional<BBTransactionReceipt> findByHash (@NotNull String hash);
}
