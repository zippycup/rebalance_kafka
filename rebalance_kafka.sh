#!/bin/bash

usage() {
  echo "$0 -b [broker_list] -h [zookeeper_host] -p [port]"
  echo "     e.g. $0 -b '1,2,3,5,9' -z localhost -p 2181"
}

create_json() {
cat <<EOF >> ${tmp_dir}/${topic}.json
{"topics":
     [{"topic": "${topic}"}],
     "version":1
}
EOF
}

zookeeper_host=localhost
port=2181
tmp_dir=build
dry_run=false
sleep=5      # 5 secs

if [ -z "${KAFKA_BIN}" ]
then
  echo "environment variable [KAFKA_BIN] not defined"
  exit 1
fi

if [ ! -d "${KAFKA_BIN}" ]
then
  echo "${KAFKA_BIN} directory does not exist"
  exit 1
fi

options='b:h:p:n'
while getopts ${options} option
do
  case $option in
    b ) broker_list=${OPTARG};;
    h ) zookeeper_host=${OPTARG};;
    p ) port=${OPTARG};;
    n ) dry_run=true;;
  esac
done

if [ -z "${broker_list}" ]
then
  usage
  exit 0
fi

rm -rf ${tmp_dir}
mkdir -p ${tmp_dir}

echo "==================================="
echo "broker_list    : ${broker_list}"
echo "zookeeper_host : ${zookeeper_host}"
echo "port           : ${port}"
echo
echo "dry_run        : ${dry_run}"
echo "==================================="
read -p "continue?[y/n]" -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]
then
  echo
else
  echo -e "\nuser chose to exit"
  exit 0
fi

count=0
topics=`sh ${KAFKA_BIN}/kafka-topics.sh --zookeeper localhost:${port} --list`

for topic in `echo ${topics}`
do
  ((count++))
  echo "==================================="
  echo "[${count}] ${topic}"

  create_json
  sh ${KAFKA_BIN}/kafka-reassign-partitions.sh --topics-to-move-json-file ${tmp_dir}/${topic}.json --broker-list "${broker_list}" --generate --zookeeper ${zookeeper_host}:${port} > ${tmp_dir}/proposed_${topic}.json
  cat ${tmp_dir}/proposed_${topic}.json | tail -1 > ${tmp_dir}/run_${topic}.json

  if [ ${dry_run} == 'true' ]
  then
    cat ${tmp_dir}/proposed_${topic}.json
  else
    START_SECS=$SECONDS
    sh ${KAFKA_BIN}/kafka-reassign-partitions.sh --reassignment-json-file ${tmp_dir}/run_${topic}.json --execute --zookeeper ${zookeeper_host}:${port}
    while true
    do
      sh ${KAFKA_BIN}/kafka-topics.sh --describe --zookeeper  ${zookeeper_host}:${port} --topic ${topic} | grep 'Isr'| awk '{ if ( length($8) != length($10) ) print "balancing";else print "balanced"}' | grep balancing > /dev/null
      if [ "$?" -ne 0 ]
      then
        break
      fi
      sleep ${sleep}
    done
    RUN_SECS=$((SECONDS-=START_SECS))
    echo "balancing completed (${RUN_SECS} secs)"
  fi

done
