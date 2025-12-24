#!/bin/bash
curl --location 'http://localhost:8083/connectors' \
--header 'Content-Type: application/json' \
--data '{
    "name": "local-cdc-with-test-database",
    "config": {
        "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
        "slot.name": "debezium_full2",
        "slot.drop.on.stop": "false",
        "publication.name": "dbz_full_publication",
        "plugin.name": "pgoutput",
        "database.server.name": "test",
        "database.dbname": "test_cdc",
        "database.hostname": "postgres",
        "database.port": "5432",
        "database.user": "postgres",
        "database.password": "postgres",
        "table.whitelist": "public\\..*",
        "include.schema.changes": "false",
        "snapshot.mode": "initial",
        "value.converter": "org.apache.kafka.connect.json.JsonConverter",
        "key.converter": "org.apache.kafka.connect.converters.LongConverter",
        "key.converter.schemas.enable": "false",
        "value.converter.schemas.enable": "false",
        "topic.prefix":"test",
        "database.history.kafka.bootstrap.servers": "broker:29092",
        "transforms": "unwrap,insertKey,extractKey",
        "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
        "transforms.unwrap.add.fields": "table",
        "transforms.unwrap.delete.handling.mode": "rewrite",
        "transforms.unwrap.operation.header": "true",
        "transforms.unwrap.drop.tombstones": "true",
        "transforms.insertKey.type": "org.apache.kafka.connect.transforms.ValueToKey",
        "transforms.insertKey.fields": "web_id",
        "transforms.extractKey.type": "org.apache.kafka.connect.transforms.ExtractField$Key",
        "transforms.extractKey.field": "web_id"
    }
}'