package com.dinomic.blockbet.aws.dynamodb;

import com.amazonaws.services.dynamodbv2.document.*;
// import org.apache.logging.log4j.LogManager;
// import org.apache.logging.log4j.Logger;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class DynamoDBService implements IDynamoDBService{

    // private static Logger LOG = LogManager.getLogger(DynamoDBService.class);

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
