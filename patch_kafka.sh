#!/bin/bash

strimzi="../../kafka"
kafka="./kafka_2.13-4.2.1"
inkless="./kafka_2.13-4.2.1-inkless"

cd "$kafka" || exit 1

# Delete all files in Strimzi that come from Kafka
find . -type f | while read -r file; do
  fileInKafka="$strimzi/$file"
  if [ -f "$fileInKafka" ]; then
    echo "Deleting $fileInKafka"
    rm "$fileInKafka"
  fi
done

# Copy all files from Inkless
cp -r "../$inkless/." "$strimzi"
