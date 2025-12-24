# CDC with Debezium, Kafka, Postgres & Elasticsearch

A production-ready Change Data Capture (CDC) pipeline using Debezium, Kafka, and PostgreSQL.

## 🚀 Quick Start

### 1. Start Services
```bash
docker-compose up -d
```

### 2. Initialize Database
```bash
# Initialize the database with the basic schema
docker exec -i postgres psql -U postgres -d postgres < database/init_schema.sql
```

### 3. Create Connector
```bash
# Create the Debezium connector
bash scripts/create_connector.sh
```

## 📂 Project Structure

- `scripts/`: Helper scripts for managing connectors (`create_connector.sh`, `update_connector.sh`)
- `database/`: SQL schemas and database initialization scripts
- `docs/`: Additional documentation and notes
- `docker-compose.yml`: Main service configuration

## 🛠 Useful Commands

```bash
# Check connector status
curl http://localhost:8083/connectors/local-cdc-with-test-database/status

# View Debezium UI
# http://localhost:8088

# View Prometheus Metrics
# http://localhost:9001
```
