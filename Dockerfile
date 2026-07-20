FROM quay.io/strimzi/kafka:1.1.0-kafka-4.2.1

USER root

RUN mkdir ../tmp && \
    cd ../tmp && \
    curl -LO https://dlcdn.apache.org/kafka/4.2.1/kafka_2.13-4.2.1.tgz && \
    tar -xvzf kafka_2.13-4.2.1.tgz

ADD inkless/core/build/distributions/kafka_2.13-4.2.1-inkless.tgz /opt/tmp
ADD patch_kafka.sh /opt/tmp

RUN cd ../tmp && \
    ./patch_kafka.sh && \
    cd ../kafka && \
    rm -r ../tmp
