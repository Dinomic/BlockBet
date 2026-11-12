package com.dinomic.blockbet.mappers;

import blockbet.openapi.model.InfosGetResponse;
import com.dinomic.blockbet.daos.Account;
import com.dinomic.blockbet.enums.Gender;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.factory.Mappers;

@Mapper
public interface GeneralMapper {
    GeneralMapper INSTANCE = Mappers.getMapper(GeneralMapper.class);

    @Mapping(target = "name", source = "username")
    @Mapping(target = "phone", source = "accountDetail.phone")
    @Mapping(target = "address", source = "accountDetail.address")
    @Mapping(target = "nationality", source = "accountDetail.nationality")
    @Mapping(target = "dateOfBirth", source = "accountDetail.dateOfBirth")
    @Mapping(target = "gender", source = "accountDetail.gender")
    InfosGetResponse accountToInfosGetResponse (Account account);

    Gender toGender(blockbet.openapi.model.Gender gender);
}
