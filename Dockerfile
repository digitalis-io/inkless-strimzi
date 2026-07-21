ARG STRIMZI_VERSION=1.1.0
ARG KAFKA_VERSION=4.2.1

FROM quay.io/strimzi/kafka:${STRIMZI_VERSION}-kafka-${KAFKA_VERSION}

# Redeclare build args needed after FROM
ARG KAFKA_VERSION
ARG INKLESS_DIST_VERSION=4.2.1-inkless

USER root

RUN mkdir ../tmp && \
    cd ../tmp && \
    curl -LO https://archive.apache.org/dist/kafka/${KAFKA_VERSION}/kafka_2.13-${KAFKA_VERSION}.tgz && \
    tar -xvzf kafka_2.13-${KAFKA_VERSION}.tgz

ADD inkless/core/build/distributions/kafka_2.13-${INKLESS_DIST_VERSION}.tgz /opt/tmp
ADD patch_kafka.sh /opt/tmp

# patch_kafka.sh reads these to locate the extracted distributions
ENV KAFKA_VERSION=${KAFKA_VERSION}
ENV INKLESS_DIST_VERSION=${INKLESS_DIST_VERSION}

RUN cd ../tmp && \
    ./patch_kafka.sh && \
    cd ../kafka && \
    rm -r ../tmp
