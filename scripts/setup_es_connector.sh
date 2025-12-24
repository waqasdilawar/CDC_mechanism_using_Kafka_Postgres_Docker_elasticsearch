#!/bin/bash

# Define variables
CONNECTOR_NAME="es-sink-connector"
CONNECT_URL="http://localhost:8083"
# Get the directory of the script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
CONFIG_FILE="$DIR/../configs/es-sink-connector.json"

# Check if the config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file $CONFIG_FILE not found!"
    exit 1
fi

echo "Deleting existing connector (if any)..."
curl -X DELETE "$CONNECT_URL/connectors/$CONNECTOR_NAME" 2>/dev/null

echo -e "\nCreating connector '$CONNECTOR_NAME'..."
curl -X POST "$CONNECT_URL/connectors" \
  -H "Content-Type: application/json" \
  -d @"$CONFIG_FILE"

echo -e "\nChecking status..."
sleep 2
curl -s "$CONNECT_URL/connectors/$CONNECTOR_NAME/status" | jq .
