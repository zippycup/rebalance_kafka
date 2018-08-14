# Rebalance all kafka brokers

## Description

When you add/delete new kafka brokers, this script will automate the update of partitions to all topics in the cluster
Tested on version: kafka-2.11-0.10.1.1

#requirement
Kafka software installed
export KAFKA_BIN=[path_to_kafkabin]
export PATH=$KAFKA_BIN:$PATH

## Installation

On a server with access to zookeeper port
git clone git@github.com:zippycup/rebalance_kafka.git

## Run utility

usage
rebalance_kafka.sh -b [broker_list] -h [zookeeper_host] -p [port] -n
     e.g. rebalance_kafka.sh -b '1,2,3,5,9' -z localhost -p 2181 -n  # dry run and show config
          rebalance_kafka.sh -b '1,2,3,5,9' -z localhost -p 2181     # run rebalance

* cd [git_clone_dir]
* sh rebalance_kafka.sh -b '1,2,3,5,9' -n
* sh rebalance_kafka.sh -b '1,2,3,5,9'
