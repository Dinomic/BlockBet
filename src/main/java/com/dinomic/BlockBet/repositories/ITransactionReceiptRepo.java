package com.dinomic.BlockBet.repositories;

import com.dinomic.BlockBet.entities.BBTransactionReceipt;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ITransactionReceiptRepo extends JpaRepository<BBTransactionReceipt, Long> {
}
