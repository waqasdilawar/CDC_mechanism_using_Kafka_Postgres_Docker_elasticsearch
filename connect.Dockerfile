# Build a Debezium Connect image with Prometheus JMX exporter agent
# Multi-stage to download and verify the JMX Exporter JAR robustly
FROM curlimages/curl:8.10.1 as downloader
ARG JMX_EXPORTER_VERSION=1.5.0
ARG ES_CONNECTOR_VERSION=15.0.2

WORKDIR /download
# Download with -fL to fail on HTTP errors and follow redirects
RUN curl -fsSL -o jmx_prometheus_javaagent.jar \
    https://github.com/prometheus/jmx_exporter/releases/download/${JMX_EXPORTER_VERSION}/jmx_prometheus_javaagent-${JMX_EXPORTER_VERSION}.jar \
  && test -s jmx_prometheus_javaagent.jar
# Download Elasticsearch connector
RUN curl -fsSL -o kafka-connect-elasticsearch.zip \
    "https://hub-downloads.confluent.io/api/plugins/confluentinc/kafka-connect-elasticsearch/versions/${ES_CONNECTOR_VERSION}/confluentinc-kafka-connect-elasticsearch-${ES_CONNECTOR_VERSION}.zip" \
  && unzip kafka-connect-elasticsearch.zip \
  && mv confluentinc-kafka-connect-elasticsearch-* elasticsearch-connector \
  && rm kafka-connect-elasticsearch.zip

FROM quay.io/debezium/connect:3.3

# Set versions and paths
ENV JMX_EXPORTER_VERSION=1.5.0 \
    JMX_EXPORTER_JAR=/kafka/libs/jmx_prometheus_javaagent.jar \
    JMX_EXPORTER_CONFIG=/kafka/config/jmx-exporter.yaml

# Ensure target directories exist (defensive; base image usually has them)
USER root
RUN mkdir -p /kafka/libs /kafka/config

# Copy the verified JAR from the downloader stage
COPY --from=downloader /download/jmx_prometheus_javaagent.jar ${JMX_EXPORTER_JAR}
# Copy Elasticsearch connector
COPY --from=downloader /download/elasticsearch-connector/lib /kafka/connect/elasticsearch

# Optionally check that the JAR is a valid ZIP (jar tool should be present with JDK)
RUN (jar tf ${JMX_EXPORTER_JAR} >/dev/null 2>&1 || unzip -l ${JMX_EXPORTER_JAR} >/dev/null 2>&1) || (echo "Invalid JMX exporter jar" && exit 1)
