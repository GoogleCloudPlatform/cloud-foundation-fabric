
## Kafka cluster with topics

``` hcl 
module "kafka_cluster_1" {
  source             = "../"
  project_id         = "example-project-id"
  kafka_cluster_id   = "example-kafka-cluster-1"
  kafka_region       = "us-central1"
  kafka_vcpu_count   = 4
  kafka_memory_bytes = 21474836480
  kafka_subnetworks  = [
    "projects/example-project/regions/us-central1/subnetworks/example-subnetwork"
  ]
  network_project_ids = [
    "example-network-project"
  ]
  kafka_rebalance_mode = "AUTO_REBALANCE_ON_SCALE_UP"
  topics = [
    {
      topic_id           = "example-topic-1"
      partition_count    = 3
      replication_factor = 2
      configs = {
        "cleanup.policy" = "compact"
        "retention.ms"   = "604800000"
      }
    },
    {
      topic_id           = "example-topic-2"
      partition_count    = 5
      replication_factor = 3
      configs = {
        "cleanup.policy" = "delete"
      }
    }
  ]
  labels = {
    team    = "example-team"
    project = "example-kafka-project"
  }
} 
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [kafka_cluster_id](variables.tf#L7) | Unique ID for the Kafka cluster | <code>string</code> | ✓ |  |
| [kafka_memory_bytes](variables.tf#L22) | The amount of memory in bytes for the Kafka cluster | <code>number</code> | ✓ |  |
| [kafka_region](variables.tf#L12) | The region where the Kafka cluster will be deployed | <code>string</code> | ✓ |  |
| [kafka_subnetworks](variables.tf#L27) | List of subnetworks for the Kafka cluster | <code>list&#40;string&#41;</code> | ✓ |  |
| [kafka_vcpu_count](variables.tf#L17) | The number of vCPUs for the Kafka cluster | <code>number</code> | ✓ |  |
| [network_project_ids](variables.tf#L46) | List of project IDs where the subnets are located | <code>list&#40;string&#41;</code> | ✓ |  |
| [project_id](variables.tf#L2) | The ID of the Google Cloud project where the Kafka cluster will be deployed | <code>string</code> | ✓ |  |
| [kafka_rebalance_mode](variables.tf#L32) | The rebalance mode for the Kafka cluster | <code>string</code> |  | <code>&#34;AUTO_REBALANCE_ON_SCALE_UP&#34;</code> |
| [labels](variables.tf#L39) | Additional labels for the Kafka cluster | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [topics](variables.tf#L52) | The list of topics to create in the Kafka cluster. | <code title="list&#40;object&#40;&#123;&#10;  topic_id           &#61; string&#10;  partition_count    &#61; optional&#40;number, 3&#41;&#10;  replication_factor &#61; optional&#40;number, 1&#41;&#10;  configs            &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;">list&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#91;&#93;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [kafka_cluster_id](outputs.tf#L2) | The ID of the Kafka cluster |  |
| [kafka_labels](outputs.tf#L12) | Labels applied to the Kafka cluster |  |
| [kafka_region](outputs.tf#L7) | The region where the Kafka cluster is deployed |  |
| [project_number](outputs.tf#L17) |  |  |
<!-- END TFDOC -->
