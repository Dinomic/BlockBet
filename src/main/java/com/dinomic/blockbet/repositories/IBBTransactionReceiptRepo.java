package com.dinomic.blockbet.repositories;

import com.dinomic.blockbet.entities.BBTransactionReceipt;
import com.dinomic.blockbet.repositories.customRepo.IBBTransactionReceiptCustomRepo;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface IBBTransactionReceiptRepo extends JpaRepository<BBTransactionReceipt, Long>, IBBTransactionReceiptCustomRepo {

}
