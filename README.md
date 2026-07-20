# [Inkless](https://github.com/aiven/inkless) on [Strimzi](https://strimzi.io/)

This repository provides quick-and-dirty instructions for running Inkless on Kubernetes with Strimzi. It allows you to experiment with the initial draft of [KIP-1150: Diskless Topics](https://cwiki.apache.org/confluence/display/KAFKA/KIP-1150%3A+Diskless+Topics) in Amazon EKS with S3 as backing object storage.

**⚠️ Important:** The code in this repository is far from enabling production-ready deployments and is intended for testing and experimentation only.

Version numbers are for now hardcoded to Strimzi 1.1.0 (Kafka 4.2.1) and Inkless 0.44 (4.2.1-inkless).


## 🔧 Building Inkless

Inkless is included as a Git submodule. To build the latest version, run:

```sh
git submodule update --init --recursive
cd inkless
./gradlew clean releaseTarGz
```


## 🧩 Patching the Strimzi Image

Kafka's official Docker image and, hence, also the Inkless image are not directly compatible with Strimzi. We patch the Strimzi image by replacing all Kafka binaries and dependencies with those from Inkless. This is done by first removing all files in the image that come with the Kafka 4.2 distribution and then adding files from the Inkless distribution.

*Note, this seems to work for now, but it may not remain compatible with future versions.*

Build the patched Strimzi image by running:

```sh
docker build -t strimzi/kafka:1.1.0-kafka-4.2.1-inkless .
```

This will create a new image with the name `strimzi/kafka:1.1.0-kafka-4.2.1-inkless`, which you can push to your own registry:

```sh
docker tag strimzi/kafka:1.1.0-kafka-4.2.1-inkless $YOUR_REGISTRY/$YOUR_IMAGE_NAME
docker push $YOUR_REGISTRY/$YOUR_IMAGE_NAME
```


## ☁️ Create an Amazon Elastic Kubernetes Service (EKS) Cluster

We use [eksctl](https://eksctl.io/) to provision an EKS cluster. Replace all `<placeholder>` values in `eks/cluster.yaml`, then run:

```sh
eksctl create cluster -f eks/cluster.yaml
```

You might either want to use an existing IAM policy or create a new one.


## 🚀 Run Inkless in Kubernetes

First, we need to deploy Postgres:

```sh
kubectl apply -f postgres/
```

Strimzi can, [for example, be installed](https://strimzi.io/quickstarts/) via:

```sh
kubectl create -f 'https://strimzi.io/install/latest?namespace=default'
```

To create an Inkless cluster via Strimzi, replace all the `<placeholder>` values in `cluster/inkless-cluster.yaml` and run:

```sh
kubectl apply -f cluster/
```


## 📊 (Optional) Enable Observability

If you are using the [Prometheus Operator](https://prometheus-operator.dev/) or the [OpenTelemetry Operator's Target Allocator](https://github.com/open-telemetry/opentelemetry-operator/tree/main/cmd/otel-allocator), you can install *PodMonitors* for the Inkless brokers and the Kafka Exporter:

```sh
kubectl apply -f o11y/
```

This should enable Prometheus/OpenTelemetry Collector to scrape Inkless metrics automatically.


## 📂 Create a Topic

We use Strimzi's *KafkaTopic* CRD to create an example topic:

```sh
kubectl apply -f example-topic.yaml
```

## 💬 Interacting with Inkless

We can now use the Kafka CLI tools to interact with the Inkless cluster. For example, we can list all topics:

```sh
kubectl exec inkless-dual-role-0 -- bin/kafka-topics.sh --bootstrap-server inkless-kafka-bootstrap:9092 --list
```

Describe the topic we just created:

```sh
kubectl exec inkless-dual-role-0 -- bin/kafka-topics.sh --bootstrap-server inkless-kafka-bootstrap:9092 --describe --topic example
```

Produce some messages to the topic:

```sh
kubectl exec -it inkless-dual-role-0 -- bin/kafka-console-producer.sh --bootstrap-server inkless-kafka-bootstrap:9092 --topic example
```

And consume them:

```sh
kubectl exec inkless-dual-role-0 -- bin/kafka-console-consumer.sh --bootstrap-server inkless-kafka-bootstrap:9092 --topic example --from-beginning
```

To run the `kafka-producer-perf-test` tool:

```sh
kubectl exec inkless-dual-role-0 -- bin/kafka-producer-perf-test.sh --topic example --record-size 1000 --num-records 1000000 --throughput -1 --producer-props bootstrap.servers=inkless-kafka-bootstrap:9092 batch.size=1048576 linger.ms=100 max.request.size=64000000
```


## 🧹 Clean Up

Remove all deployed resources:

```sh
kubectl delete -f example-topic.yaml
kubectl delete -f o11y/ # If installed
kubectl delete -f cluster/
kubectl delete -f postgres/
```

and delete the EKS cluster:

```sh
eksctl delete cluster -f eks/cluster.yaml --disable-nodegroup-eviction
```

To remove all created objects in the S3 bucket:

```sh
aws s3 rm s3://$S3_BUCKET_NAME/inkless --recursive
```
