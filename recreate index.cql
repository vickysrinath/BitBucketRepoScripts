#!/bin/bash

# Configuration
CASSANDRA_HOST="your_cassandra_host"  # Replace with your Cassandra host address
CASSANDRA_PORT="your_cassandra_port"  # Replace with your Cassandra port number
KEYSPACE="your_keyspace_name"         # Replace with your keyspace name

# Drop indexes and generate createindex.cql
cqlsh -e "DESCRIBE KEYSPACE $KEYSPACE" $CASSANDRA_HOST $CASSANDRA_PORT | grep -E "^\s*CREATE INDEX" | awk -F'[ .]' '{print $5}' | while read -r index_name; do
    echo "DROP INDEX IF EXISTS $KEYSPACE.$index_name;"
done > dropindex.cql

# Recreate indexes and append to createindex.cql
cqlsh -e "DESCRIBE KEYSPACE $KEYSPACE" $CASSANDRA_HOST $CASSANDRA_PORT | grep -E "^\s*CREATE INDEX" | awk -F'[ .]' '{print "CREATE INDEX IF NOT EXISTS " $5 " ON " $3 "." $4 " (" $6 ");"}' >> createindex.cql

echo "All DROP INDEX and CREATE INDEX statements have been written to dropindex.cql and createindex.cql."
