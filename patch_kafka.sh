#!/bin/bash
#
# patch_kafka.sh — swap the vanilla Kafka binaries in a Strimzi image for the
# Inkless build.
#
# The official Strimzi Kafka image is not directly compatible with the Inkless
# distribution, so we replace Kafka's files in place: first delete every file in
# the Strimzi Kafka install (../../kafka) that also exists in the vanilla Kafka
# distribution, then copy the Inkless distribution's files over the top.
#
# Called from the Dockerfile inside the extracted-tarballs dir (/opt/tmp), with
# both distributions already unpacked alongside this script:
#   KAFKA_VERSION=<x> INKLESS_DIST_VERSION=<y> ./patch_kafka.sh
#
# Inputs (env vars, with defaults):
#   KAFKA_VERSION         vanilla Kafka version    -> ./kafka_2.13-<KAFKA_VERSION>
#   INKLESS_DIST_VERSION  Inkless dist version     -> ./kafka_2.13-<INKLESS_DIST_VERSION>
#
# Result: ../../kafka becomes a Strimzi layout running Inkless. Exits non-zero if
# the vanilla Kafka directory is missing.

strimzi="../../kafka"
kafka="./kafka_2.13-${KAFKA_VERSION:-4.2.1}"
inkless="./kafka_2.13-${INKLESS_DIST_VERSION:-4.2.1-inkless}"

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
