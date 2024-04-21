package com.dinomic.BlockBet.aws.dynamodb;

import com.amazonaws.services.dynamodbv2.document.Item;
import com.amazonaws.services.dynamodbv2.document.PutItemOutcome;

import javax.validation.constraints.NotNull;

public interface IDynamoDBService {

    PutItemOutcome putItemToTable(@NotNull String tableName, Item item);
}
