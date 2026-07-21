ARG STRIMZI_VERSION=1.1.0
ARG KAFKA_VERSION=4.2.1

FROM quay.io/strimzi/kafka:${STRIMZI_VERSION}-kafka-${KAFKA_VERSION}

# Redeclare build args needed after FROM
ARG KAFKA_VERSION
ARG INKLESS_DIST_VERSION=4.2.1-inkless

USER root

RUN mkdir ../tmp && \
    cd ../tmp && \
    curl -fLO https://archive.apache.org/dist/kafka/${KAFKA_VERSION}/kafka_2.13-${KAFKA_VERSION}.tgz && \
    tar -xvzf kafka_2.13-${KAFKA_VERSION}.tgz

ADD inkless/core/build/distributions/kafka_2.13-${INKLESS_DIST_VERSION}.tgz /opt/tmp
ADD patch_kafka.sh /opt/tmp

# Pass the versions to patch_kafka.sh for this command only; don't persist them
# as ENV into the final runtime image.
RUN cd ../tmp && \
    KAFKA_VERSION="$KAFKA_VERSION" INKLESS_DIST_VERSION="$INKLESS_DIST_VERSION" ./patch_kafka.sh && \
    cd ../kafka && \
    rm -r ../tmp
