**Debezium**

_Stream changes from your database._


[Debezium](https://debezium.io/documentation/reference/stable/features.html) is an open source distributed platform for **change data capture**. Start it up, point it at your databases, and your apps can start responding to all of the inserts, updates, and deletes that other apps commit to your databases. Debezium is durable and fast, so your apps can respond quickly and never miss an event, even when things go wrong.

**Starting the services**

Using Debezium requires three separate services: ZooKeeper, Kafka, and the Debezium connector service. In this tutorial, you will set up a single instance of each service using Docker and the Debezium container images.


**Monitoring**

The Debezium PostgreSQL connector provides two types of metrics that are in addition to the built-in support for JMX metrics that Zookeeper, Kafka, and Kafka Connect provide.

**Snapshot metrics:**
provide information about connector operation while performing a snapshot.

**Streaming metrics:**
provide information about connector operation when the connector is capturing changes and streaming change event records.

[Debezium monitoring documentation](https://debezium.io/documentation/reference/stable/operations/monitoring.html#monitoring-debezium) provides details for how to expose these metrics by using JMX.
