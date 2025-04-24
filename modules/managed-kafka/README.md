# Managed Kafka Module

This module allows simplified creation and management of Google Cloud Managed Kafka clusters, including topics, Kafka Connect clusters, and connectors.

## TOC

<!-- BEGIN TOC -->
- [TOC](#toc)
- [Simple Cluster Example](#simple-cluster-example)
- [Cluster with Topics](#cluster-with-topics)
- [Cluster with Kafka Connect](#cluster-with-kafka-connect)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Simple Cluster Example

This example creates a basic Managed Kafka cluster.

```hcl
module "kafka-cluster" {
  source     = "./fabric/modules/managed-kafka"
  project_id = var.project_id
  location   = var.regions.primary
  cluster_id = "my-kafka-cluster"

  capacity_config = {
    vcpu_count   = 3
    memory_bytes = 3221225472 # 3 GiB
  }

  subnets = [
    var.subnets.primary.id
  ]

  labels = {
    environment = "development"
  }
}
# tftest modules=1 resources=1 inventory=simple.yaml
```

## Cluster with Topics

This example creates a Managed Kafka cluster along with predefined topics.

```hcl
module "kafka-cluster-with-topics" {
  source     = "./fabric/modules/managed-kafka"
  project_id = var.project_id
  location   = "europe-west1"
  cluster_id = "my-kafka-cluster-topics"

  capacity_config = {
    vcpu_count   = 6
    memory_bytes = 6442450944 # 6 GiB
  }

  subnets = [var.subnets.primary.id]

  topics = {
    topic-a = {
      partition_count    = 3
      replication_factor = 3
      configs = {
        "cleanup.policy" = "delete"
      }
    }
    topic-b = {
      partition_count    = 6
      replication_factor = 3
    }
  }
}
# tftest modules=1 resources=3 inventory=topics.yaml
```

## Cluster with Kafka Connect

This example demonstrates creating a Kafka cluster, a Kafka Connect cluster, and a connector. Note that Connect resources require the `google-beta` provider.

```hcl

module "gcs" {
  source     = "./fabric/modules/gcs"
  project_id = var.project_id
  location   = var.region
  name       = "gmk-sink"
  prefix     = var.prefix
}

module "vpc" {
  source     = "./fabric/modules/net-vpc"
  project_id = var.project_id
  name       = "vpc"
  subnets = [
    {
      ip_cidr_range = "10.0.0.0/20"
      name          = "subnet1"
      region        = var.region
    },
    {
      ip_cidr_range = "10.0.16.0/20"
      name          = "subnet2"
      region        = var.region
    },
    {
      ip_cidr_range = "10.0.32.0/20"
      name          = "subnet3"
      region        = var.region
    },
  ]
}

module "kafka-cluster-with-connect" {
  source     = "./fabric/modules/managed-kafka"
  project_id = var.project_id
  location   = var.region
  cluster_id = "my-kafka-cluster-connect"

  capacity_config = {
    vcpu_count   = 3
    memory_bytes = 3221225472 # 3 GiB
  }

  subnets = [
    module.vpc.subnet_ids["${var.region}/subnet1"]
  ]

  connect_clusters = {
    my-connect-cluster = {
      vcpu_count     = 3
      memory_bytes   = 3221225472 # 3 GiB
      primary_subnet = module.vpc.subnet_ids["${var.region}/subnet1"]
      additional_subnets = [
        module.vpc.subnet_ids["${var.region}/subnet2"],
        module.vpc.subnet_ids["${var.region}/subnet3"]
      ]
    }
  }

  connect_connectors = {
    my-gcs-connector = {
      connect_cluster = "my-connect-cluster"
      configs = {
        "connector.class"                = "io.aiven.kafka.connect.gcs.GcsSinkConnector"
        "file.name.prefix"               = ""
        "format.output.type"             = "json"
        "gcs.bucket.name"                = module.gcs.name
        "gcs.credentials.default"        = "true"
        "key.converter"                  = "org.apache.kafka.connect.storage.StringConverter"
        "tasks.max"                      = "3"
        "topics"                         = "topic1"
        "value.converter"                = "org.apache.kafka.connect.json.JsonConverter"
        "value.converter.schemas.enable" = "false"
      }
      task_restart_policy = {
        minimum_backoff = "60s"
        maximum_backoff = "300s"
      }
    }
  }
}
# tftest modules=3 resources=11 inventory=connect.yaml
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [capacity_config](variables.tf#L17) | Capacity configuration for the Kafka cluster. | <code title="object&#40;&#123;&#10;  vcpu_count   &#61; number&#10;  memory_bytes &#61; number&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [cluster_id](variables.tf#L25) | The ID of the Kafka cluster. | <code>string</code> | ✓ |  |
| [location](variables.tf#L79) | The GCP region for the Kafka cluster. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L84) | The ID of the project where the Kafka cluster will be created. | <code>string</code> | ✓ |  |
| [subnets](variables.tf#L95) | List of VPC subnets for the Kafka cluster network configuration. | <code>list&#40;string&#41;</code> | ✓ |  |
| [connect_clusters](variables.tf#L30) | Map of Kafka Connect cluster configurations to create. | <code title="map&#40;object&#40;&#123;&#10;  vcpu_count         &#61; number&#10;  memory_bytes       &#61; number&#10;  primary_subnet     &#61; string&#10;  project_id         &#61; optional&#40;string&#41;&#10;  location           &#61; optional&#40;string&#41;&#10;  additional_subnets &#61; optional&#40;list&#40;string&#41;&#41;&#10;  dns_domain_names   &#61; optional&#40;list&#40;string&#41;&#41;&#10;  labels             &#61; optional&#40;map&#40;string&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [connect_connectors](variables.tf#L46) | Map of Kafka Connect Connectors to create. | <code title="map&#40;object&#40;&#123;&#10;  connect_cluster &#61; string&#10;  configs         &#61; map&#40;string&#41;&#10;  task_restart_policy &#61; optional&#40;object&#40;&#123;&#10;    minimum_backoff &#61; optional&#40;string&#41;&#10;    maximum_backoff &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [kms_key](variables.tf#L67) | Customer-managed encryption key (CMEK) used for the Kafka cluster. | <code>string</code> |  | <code>null</code> |
| [labels](variables.tf#L73) | Labels to apply to the Kafka cluster. | <code>map&#40;string&#41;</code> |  | <code>null</code> |
| [rebalance_mode](variables.tf#L89) | Rebalancing mode for the Kafka cluster. | <code>string</code> |  | <code>null</code> |
| [topics](variables.tf#L100) | Map of Kafka topics to create within the cluster. | <code title="map&#40;object&#40;&#123;&#10;  replication_factor &#61; number&#10;  partition_count    &#61; number&#10;  configs            &#61; optional&#40;map&#40;string&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [connect_cluster_ids](outputs.tf#L17) | Map of Kafka Connect cluster IDs. |  |
| [connect_connectors](outputs.tf#L25) | Map of Kafka Connect Connector IDs. |  |
| [id](outputs.tf#L33) | The ID of the Managed Kafka cluster. |  |
| [topic_ids](outputs.tf#L38) | Map of Kafka topic IDs. |  |
<!-- END TFDOC -->
