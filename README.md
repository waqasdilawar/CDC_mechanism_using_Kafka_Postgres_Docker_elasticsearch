# Change Data Capture (CDC) with Debezium, Kafka, PostgreSQL & Elasticsearch

## 📋 Overview

This project implements a production-ready **Change Data Capture (CDC)** pipeline using **Debezium** to capture real-time database changes from **PostgreSQL** and stream them to **Apache Kafka**. The captured events can be optionally sinked to **Elasticsearch** for search and analytics. The entire stack is containerized with **Docker Compose** and includes comprehensive monitoring via **Prometheus**.

### What is CDC?

Change Data Capture is a design pattern that identifies and tracks changes to data in a database, allowing downstream systems to react to those changes in real-time. This project uses Debezium, which leverages PostgreSQL's logical replication feature to capture row-level changes (INSERT, UPDATE, DELETE) without modifying application code.

## 🏗️ Architecture

```
┌─────────────┐     Logical        ┌──────────────────┐      Kafka        ┌─────────┐
│ PostgreSQL  │─────Replication────▶│ Debezium Connect │─────Topics───────▶│  Kafka  │
│   Database  │     (pgoutput)      │   (CDC Source)   │                   │ Broker  │
└─────────────┘                     └──────────────────┘                   └─────────┘
                                             │                                   │
                                             │ Metrics                           │
                                             ▼                                   ▼
                                    ┌──────────────┐              ┌──────────────────────┐
                                    │ Prometheus   │              │ Elasticsearch Sink   │
                                    │  Monitoring  │              │   Connect (Optional) │
                                    └──────────────┘              └──────────────────────┘
                                                                            │
                                                                            ▼
                                                                   ┌─────────────────┐
                                                                   │ Elasticsearch   │
                                                                   │  (Search/Index) │
                                                                   └─────────────────┘
```

## 🔧 Components

| Component | Description | Port(s) | Image |
|-----------|-------------|---------|-------|
| **ZooKeeper** | Kafka coordination service | `2181` | `confluentinc/cp-zookeeper:5.5.1` |
| **Kafka Broker** | Message streaming platform | `9092`, `29092` | `confluentinc/cp-server:5.5.1` |
| **Debezium Connect** | CDC source connector for PostgreSQL | `8083`, `8081` (metrics) | `quay.io/debezium/connect` |
| **PostgreSQL** | Source database with logical replication | `5433` (→5432) | `postgres:alpine` |
| **Elasticsearch** | Optional search/analytics sink | `9200`, `9300` | `elasticsearch:8.4.1` |
| **Elasticsearch Sink** | Kafka Connect sink for Elasticsearch | `8086` | `quay.io/debezium/connect` |
| **Debezium UI** | Web interface for connector management | `8088` | `quay.io/debezium/debezium-ui` |
| **Prometheus** | Metrics collection and monitoring | `9001` (→9090) | `prom/prometheus:latest` |

## 📦 Prerequisites

- **Docker** (v20.10+)
- **Docker Compose** (v1.29+ or v2.x)
- Basic understanding of Kafka, PostgreSQL, and CDC concepts
- **JDBC Connector** (optional): Download `confluentinc-kafka-connect-jdbc` from [Confluent Hub](https://www.confluent.io/hub/confluentinc/kafka-connect-jdbc)
- **Elasticsearch Connector** (optional): Download `confluentinc-kafka-connect-elasticsearch` from [Confluent Hub](https://www.confluent.io/hub/confluentinc/kafka-connect-elasticsearch)

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone <repository-url>
cd CDC_mechanism_using_Kafka_Postgres_Docker_elasticsearch
```

### 2. Download Required Connectors (Optional)

If you want to use JDBC or Elasticsearch sinks, download and extract the connectors:

```bash
# Create jars directory
mkdir -p jars

# Download JDBC connector (example)
# Extract to jars/confluentinc-kafka-connect-jdbc-10.0.1/

# Download Elasticsearch connector (example)
# Extract to jars/confluentinc-kafka-connect-elasticsearch-10.0.2/
```

### 3. Start the Environment

```bash
# Start all services
docker-compose up -d

# Check service status
docker-compose ps

# View logs
docker-compose logs -f jdbc-source-connect
```

### 4. Initialize the Database

```bash
# Connect to PostgreSQL container
docker exec -it postgres bash

# Connect to psql
psql -U postgres postgres

# Run the schema creation script
\i /path/to/04-basic-database-schema.sql
# OR manually copy-paste the SQL from the file
```

Alternatively, execute the SQL file directly:

```bash
docker exec -i postgres psql -U postgres -d postgres < "04- basic database schema.sql"
```

### 5. Access the Web Interfaces

- **Debezium UI**: [http://localhost:8088](http://localhost:8088) - Manage connectors
- **Prometheus**: [http://localhost:9001](http://localhost:9001) - View metrics
- **Kafka Connect REST API**: [http://localhost:8083](http://localhost:8083) - REST API endpoints
- **Elasticsearch** (if enabled): [http://localhost:9200](http://localhost:9200)

## 📝 Project Files

### Configuration Files

| File | Description |
|------|-------------|
| [`docker-compose.yml`](./docker-compose.yml) | Main Docker Compose configuration with Kafka setup |
| [`docker-compose-redpanda.yml`](./docker-compose-redpanda.yml) | Alternative setup using Redpanda instead of Kafka |
| [`01- Create Kafka Connect CDC Configurations`](./01-%20Create%20Kafka%20Connect%20CDC%20Configurations) | Initial CDC connector configuration (JSON) |
| [`02- Update Kafka Connect CDC Configurations.json`](./02-%20Update%20Kafka%20Connect%20CDC%20Configurations.json) | Updated connector configuration template |
| [`04- basic database schema.sql`](./04-%20basic%20database%20schema.sql) | PostgreSQL schema with CDC-enabled tables |
| [`Commands/01- CDC Session on September 16 - 2021.txt`](./Commands/01-%20CDC%20Session%20on%20September%2016%20-%202021.txt) | Step-by-step tutorial for setting up CDC |

### Database Schema

The project includes a sample `test_cdc` database with three tables:

- **`order_equipment_detail`**: Order-equipment relationship with version tracking
- **`equipment`**: Equipment catalog with product references
- **`product`**: Product catalog with manufacturer references

All tables are configured with:
- Primary keys on `web_id` column
- Timestamp tracking (`date_created`, `date_updated`)
- **`REPLICA IDENTITY FULL`** - captures complete row state (before/after)
- Included in PostgreSQL publication `dbz_full_publication`

## 🔌 Setting Up the CDC Connector

### Step 1: Verify PostgreSQL Configuration

Ensure logical replication is enabled (already configured in `docker-compose.yml`):

```bash
# Connect to PostgreSQL
docker exec -it postgres psql -U postgres -d test_cdc

# Verify wal_level is set to logical
SHOW wal_level;  -- Should return 'logical'

# Check replica identity for tables
SELECT CASE relreplident
    WHEN 'd' THEN 'default'
    WHEN 'n' THEN 'nothing'
    WHEN 'f' THEN 'full'
    WHEN 'i' THEN 'index'
END AS replica_identity
FROM pg_class
WHERE oid IN ('order_equipment_detail'::regclass, 'equipment'::regclass, 'product'::regclass);

# Verify publication exists
SELECT * FROM pg_publication WHERE pubname = 'dbz_full_publication';

# Check which tables are in the publication
SELECT * FROM pg_publication_tables WHERE pubname = 'dbz_full_publication';
```

### Step 2: Create the Debezium Connector

**Option A: Using Debezium UI**

1. Navigate to [http://localhost:8088](http://localhost:8088)
2. Click "Create a connector"
3. Select "PostgreSQL"
4. Paste configuration from `01- Create Kafka Connect CDC Configurations`

**Option B: Using REST API**

```bash
curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d @"01- Create Kafka Connect CDC Configurations"
```

**Option C: Manual Configuration**

```bash
curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d '{
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
    "topic.prefix": "test",
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
```

### Step 3: Verify Connector Status

```bash
# Check connector status
curl http://localhost:8083/connectors/local-cdc-with-test-database/status

# List all connectors
curl http://localhost:8083/connectors

# View connector configuration
curl http://localhost:8083/connectors/local-cdc-with-test-database
```

### Step 4: Verify Replication Slot in PostgreSQL

```sql
-- Check replication slot is active
SELECT * FROM pg_replication_slots WHERE slot_name = 'debezium_full2';

-- Monitor replication status (should show 'streaming')
SELECT * FROM pg_stat_replication;
```

## 📊 Understanding the Configuration

### Key Configuration Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| `plugin.name` | `pgoutput` | Native PostgreSQL logical decoding plugin (Postgres 10+) |
| `slot.name` | `debezium_full2` | Replication slot name in PostgreSQL |
| `publication.name` | `dbz_full_publication` | PostgreSQL publication containing tracked tables |
| `snapshot.mode` | `initial` | Takes initial snapshot of existing data before streaming changes |
| `topic.prefix` | `test` | Prefix for Kafka topics (results in `test.public.table_name`) |
| `table.whitelist` | `public\\..*` | Captures all tables in the `public` schema |

### Single Message Transforms (SMTs)

The connector uses three chained transformations to simplify event structure:

1. **`unwrap` (ExtractNewRecordState)**
   - Extracts the `after` state from Debezium's complex envelope
   - Adds metadata fields (e.g., `table` name)
   - Handles DELETE operations by rewriting them
   - Sets operation type in message header
   - Drops tombstone messages

2. **`insertKey` (ValueToKey)**
   - Copies the `web_id` field from message value to key
   - Enables proper Kafka partitioning and compaction

3. **`extractKey` (ExtractField$Key)**
   - Extracts only the `web_id` from the key structure
   - Results in a simple long value as the message key

**Without SMTs**, a Debezium event looks like:
```json
{
  "before": null,
  "after": {"web_id": 1, "item": "foo", "version": 1},
  "source": {...},
  "op": "c",
  "ts_ms": 1234567890
}
```

**With SMTs**, the same event becomes:
```json
{
  "web_id": 1,
  "item": "foo",
  "version": 1,
  "__table": "order_equipment_detail"
}
```

## 🧪 Testing the CDC Pipeline

### 1. Produce Database Changes

```bash
# Connect to PostgreSQL
docker exec -it postgres psql -U postgres -d test_cdc

# Insert new records
INSERT INTO order_equipment_detail (web_id, version, date_created, date_updated, equipment_id)
VALUES (1, 0, NOW(), NOW(), 100);

INSERT INTO equipment (web_id, version, product_id)
VALUES (100, 0, 200);

INSERT INTO product (web_id, version, manufacturer_id)
VALUES (200, 0, 300);

# Update a record
UPDATE order_equipment_detail
SET last_segment_id = 42
WHERE web_id = 1;

# Delete a record
DELETE FROM product WHERE web_id = 200;
```

### 2. Consume Events from Kafka

```bash
# Enter the Kafka broker container
docker exec -it broker bash

# List all topics
kafka-topics --bootstrap-server broker:29092 --list

# Consume from a specific table topic
kafka-console-consumer \
  --bootstrap-server broker:29092 \
  --topic test.public.order_equipment_detail \
  --from-beginning

# Consume with key and headers
kafka-console-consumer \
  --bootstrap-server broker:29092 \
  --topic test.public.order_equipment_detail \
  --from-beginning \
  --property print.key=true \
  --property print.headers=true \
  --property key.separator=" | "
```

### 3. Expected Output

For an INSERT operation, you should see output similar to:

```json
1 | {
  "web_id": 1,
  "version": 0,
  "date_created": "2025-11-20T11:22:29.123456Z",
  "date_updated": "2025-11-20T11:22:29.123456Z",
  "equipment_id": 100,
  "last_segment_id": null,
  "last_completed_segment_id": null,
  "__table": "order_equipment_detail"
}
```

## 🔄 Updating the Connector

To add more tables or modify configuration:

### 1. Add New Table to Publication

```sql
-- Create new table
CREATE TABLE new_table (
    web_id bigint PRIMARY KEY,
    data varchar(100)
);

-- Set replica identity
ALTER TABLE new_table REPLICA IDENTITY FULL;

-- Update publication
ALTER PUBLICATION dbz_full_publication ADD TABLE new_table;

-- Verify
SELECT * FROM pg_publication_tables WHERE pubname = 'dbz_full_publication';
```

### 2. Update Connector Configuration

```bash
curl -X PUT http://localhost:8083/connectors/local-cdc-with-test-database/config \
  -H "Content-Type: application/json" \
  -d @"02- Update Kafka Connect CDC Configurations.json"
```

The connector will automatically detect the new table and start capturing changes.

## 📈 Monitoring with Prometheus

### Accessing Metrics

- **Prometheus UI**: [http://localhost:9001](http://localhost:9001)
- **Connector Metrics Endpoint**: [http://localhost:8081/metrics](http://localhost:8081/metrics)

### Key Metrics to Monitor

**Snapshot Metrics:**
- `debezium_metrics_SnapshotRowsScanned` - Rows scanned during initial snapshot
- `debezium_metrics_SnapshotCompleted` - Snapshot completion status

**Streaming Metrics:**
- `debezium_metrics_TotalNumberOfEventsSeen` - Total events captured
- `debezium_metrics_NumberOfCommittedTransactions` - Committed transactions
- `debezium_metrics_MilliSecondsBehindSource` - Replication lag
- `debezium_metrics_LastEvent` - Timestamp of last processed event

### Sample Prometheus Queries

```promql
# Events captured per second
rate(debezium_metrics_TotalNumberOfEventsSeen[1m])

# Replication lag in seconds
debezium_metrics_MilliSecondsBehindSource / 1000

# Connector uptime
time() - debezium_metrics_ConnectedTimestamp / 1000
```

## 🐘 Alternative Setup: Redpanda

This project includes an alternative Docker Compose configuration using **Redpanda**, a Kafka-compatible streaming platform:

```bash
# Start with Redpanda instead of Kafka
docker-compose -f docker-compose-redpanda.yml up -d

# Access Redpanda Console
# http://localhost:8080
```

**Differences:**
- Lighter weight and faster startup than Kafka
- No ZooKeeper dependency
- Built-in schema registry and HTTP proxy
- Kafka-compatible API

## 🔍 Troubleshooting

### Connector Fails to Start

**Issue:** Connector status shows `FAILED`

```bash
# Check detailed error
curl http://localhost:8083/connectors/local-cdc-with-test-database/status
```

**Common Causes:**
- PostgreSQL not reachable: Verify `database.hostname` and network connectivity
- Authentication failed: Check `database.user` and `database.password`
- Missing publication: Create publication with `CREATE PUBLICATION dbz_full_publication FOR TABLE ...`
- WAL level not logical: Ensure `wal_level=logical` in PostgreSQL config

### Replication Slot Already Exists

**Issue:** Error: `replication slot "debezium_full2" already exists`

**Solution:**

```sql
-- Drop the existing slot (WARNING: loses replication position)
SELECT pg_drop_replication_slot('debezium_full2');

-- Or, set "slot.drop.on.stop": "true" in connector config
```

### Tables Not Being Captured

**Issue:** Changes to tables not appearing in Kafka

**Checks:**

```sql
-- 1. Verify table is in publication
SELECT * FROM pg_publication_tables WHERE pubname = 'dbz_full_publication';

-- 2. Check replica identity
SELECT relname, CASE relreplident
    WHEN 'd' THEN 'default'
    WHEN 'f' THEN 'full'
    WHEN 'i' THEN 'index'
    WHEN 'n' THEN 'nothing'
END AS replica_identity
FROM pg_class
WHERE relname IN ('your_table_name');

-- 3. Verify table matches whitelist pattern
-- Check "table.whitelist": "public\\..*" in connector config
```

**Solution:**

```sql
-- Add table to publication
ALTER PUBLICATION dbz_full_publication ADD TABLE your_table_name;

-- Set replica identity if not set
ALTER TABLE your_table_name REPLICA IDENTITY FULL;

-- Restart connector
```

### High Replication Lag

**Issue:** `MilliSecondsBehindSource` metric is increasing

**Possible Causes:**
- Large transactions in PostgreSQL
- Network latency between Postgres and Kafka Connect
- Insufficient resources allocated to Kafka Connect

**Solutions:**
- Increase `max_wal_size` in PostgreSQL
- Scale up Kafka Connect instances
- Tune `max.batch.size` in connector config

### Connector Metrics Not Available

**Issue:** Prometheus shows no metrics for Debezium

**Checks:**

```bash
# 1. Verify metrics endpoint is accessible
curl http://localhost:8081/metrics

# 2. Check Prometheus targets at http://localhost:9001/targets
# Should show jdbc-source-connect:8080 as UP

# 3. Check prometheus.yml configuration
docker exec prometheus cat /etc/prometheus/prometheus.yml
```

## 🛠️ Useful Commands

### Docker Management

```bash
# View logs for specific service
docker-compose logs -f jdbc-source-connect
docker-compose logs -f postgres

# Restart a service
docker-compose restart jdbc-source-connect

# Stop all services
docker-compose down

# Stop and remove volumes (WARNING: deletes data)
docker-compose down -v

# Check resource usage
docker stats
```

### PostgreSQL Commands

```bash
# Connect to database
docker exec -it postgres psql -U postgres -d test_cdc

# Backup database
docker exec postgres pg_dump -U postgres test_cdc > backup.sql

# Restore database
docker exec -i postgres psql -U postgres test_cdc < backup.sql

# List databases
docker exec -it postgres psql -U postgres -c "\l"

# List tables
docker exec -it postgres psql -U postgres -d test_cdc -c "\dt"
```

### Kafka Commands

```bash
# Enter broker container
docker exec -it broker bash

# List topics
kafka-topics --bootstrap-server broker:29092 --list

# Describe topic
kafka-topics --bootstrap-server broker:29092 --describe --topic test.public.order_equipment_detail

# Delete topic (if needed)
kafka-topics --bootstrap-server broker:29092 --delete --topic test.public.order_equipment_detail

# Check consumer groups
kafka-consumer-groups --bootstrap-server broker:29092 --list

# View offsets for a consumer group
kafka-consumer-groups --bootstrap-server broker:29092 --describe --group <group-id>
```

### Kafka Connect REST API

```bash
# List all connectors
curl http://localhost:8083/connectors

# Get connector status
curl http://localhost:8083/connectors/local-cdc-with-test-database/status

# Get connector config
curl http://localhost:8083/connectors/local-cdc-with-test-database

# Pause connector
curl -X PUT http://localhost:8083/connectors/local-cdc-with-test-database/pause

# Resume connector
curl -X PUT http://localhost:8083/connectors/local-cdc-with-test-database/resume

# Restart connector
curl -X POST http://localhost:8083/connectors/local-cdc-with-test-database/restart

# Delete connector
curl -X DELETE http://localhost:8083/connectors/local-cdc-with-test-database

# List connector plugins
curl http://localhost:8083/connector-plugins
```

## 📚 Learning Resources

### Official Documentation

- **Debezium**: [https://debezium.io/documentation/](https://debezium.io/documentation/)
  - [PostgreSQL Connector](https://debezium.io/documentation/reference/stable/connectors/postgresql.html)
  - [Transformations](https://debezium.io/documentation/reference/stable/transformations/)
- **Kafka Connect**: [https://kafka.apache.org/documentation/#connect](https://kafka.apache.org/documentation/#connect)
  - [REST API Reference](https://docs.confluent.io/platform/current/connect/references/restapi.html)
- **PostgreSQL Logical Replication**: [https://www.postgresql.org/docs/current/logical-replication.html](https://www.postgresql.org/docs/current/logical-replication.html)
- **Prometheus**: [https://prometheus.io/docs/](https://prometheus.io/docs/)

### Tutorials & Guides

- [Debezium Tutorial](https://debezium.io/documentation/reference/stable/tutorial.html)
- [Understanding CDC Patterns](https://www.confluent.io/blog/guide-to-change-data-capture-with-apache-kafka/)
- [PostgreSQL Replication Slots](https://www.postgresql.org/docs/current/logicaldecoding-explanation.html)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## 📄 License

This project is provided as-is for educational and demonstration purposes.

## 💬 Support

For questions or issues:
1. Check the [Troubleshooting](#-troubleshooting) section
2. Review official [Debezium Documentation](https://debezium.io/documentation/)
3. Open an issue in this repository

---

**Happy streaming! 🚀**
