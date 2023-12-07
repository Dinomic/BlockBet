package com.dinomic.BlockBet.mappers;

import blockbet.openapi.model.ReceiptsGetResponseEntry;
import com.dinomic.BlockBet.entities.BBTransactionReceipt;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.factory.Mappers;

import java.util.List;

@Mapper
public interface GeneralMapper {


    GeneralMapper INSTANCE = Mappers.getMapper(GeneralMapper.class);


    @Mapping(target = "hash", source = "hash")
    @Mapping(target = "fromAddress", source = "fromAddress")
    @Mapping(target = "toAddress", source = "toAddress")
    @Mapping(target = "blockHash", source = "blockHash")
    @Mapping(target = "blockNumber", source = "blockNumber")
    @Mapping(target = "gasUsed", source = "gasUsed")
    @Mapping(target = "effectiveGasPrice", source = "effectiveGasPrice")
    ReceiptsGetResponseEntry bbTransactionReceiptToReceiptsGetResponseEntry(BBTransactionReceipt receipt);

    List<ReceiptsGetResponseEntry> bbTransactionReceiptsToReceiptsGetResponseEntries (List<BBTransactionReceipt> receipt);
}
