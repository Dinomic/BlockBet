package com.dinomic.blockbet.aws.dynamodb;

import com.amazonaws.services.dynamodbv2.document.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
@Slf4j
public class DynamoDBService implements IDynamoDBService{
    @Autowired
    DynamoDB dynamoDB;

    @Override
    public PutItemOutcome putItemToTable(String tableName, Item item) {
        Table table = dynamoDB.getTable("Betting");
        table.putItem(new Item()
                .withPrimaryKey(new PrimaryKey().addComponent("PartitionKey", "PartitionKeyValue"))
                .withKeyComponent("Sortkey", "SortKeyValue"));
        return null;
    }
}
