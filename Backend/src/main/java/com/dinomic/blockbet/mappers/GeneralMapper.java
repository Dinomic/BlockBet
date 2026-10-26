package com.dinomic.blockbet.mappers;

import blockbet.openapi.model.InfosGetResponse;
import com.dinomic.blockbet.daos.Account;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.factory.Mappers;

@Mapper
public interface GeneralMapper {
    GeneralMapper INSTANCE = Mappers.getMapper(GeneralMapper.class);

    @Mapping(target = "name", source = "username")
    InfosGetResponse accountToInfosGetResponse (Account account);
}
