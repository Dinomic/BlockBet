package com.dinomic.BlockBet.repositories;

import com.dinomic.BlockBet.entities.BBTransactionReceipt;
import com.dinomic.BlockBet.repositories.customRepo.IBBTransactionReceiptCustomRepo;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface IBBTransactionReceiptRepo extends JpaRepository<BBTransactionReceipt, Long>, IBBTransactionReceiptCustomRepo {

}
