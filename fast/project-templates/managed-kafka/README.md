# Managed Kafka Cluster with Topics

This setup allows creating and configuring a managed Kafka cluster using [Google Cloud Managed Service for Apache Kafka](https://cloud.google.com/managed-service-for-apache-kafka), with configurable topics, networking, and labels. It is designed to be FAST-compliant and integrates seamlessly with existing Google Cloud infrastructure.

## Prerequisites

The [`project.yaml`](./project.yaml) file describes the project-level configuration needed in terms of API activation and IAM bindings.

If you are deploying this inside a FAST-enabled organization, the file can be lightly edited to match your configuration and then used directly in the [project factory](../../stages/2-project-factory/).

For non-FAST setups, use the `project.yaml` file as a reference to configure your project manually:

- Enable the APIs listed under `services`.
- Grant the permissions listed under `iam` to the principal running Terraform, either a service account or a human user.

## Variable Configuration

Configuration is primarily done via the `kafka_config` and `topics` variables. Key considerations:

- The Kafka cluster is deployed in the specified region and subnetworks.
- Topics can be configured with partition count, replication factor, and additional settings.
- Labels can be added for resource organization and management.

Bringing up a cluster and the associated topics from scratch will require approximately 20–30 minutes.

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [kafka_config](variables.tf#L23) | Configuration for the Kafka cluster. | <code title="object&#40;&#123;&#10;  cluster_id     &#61; string&#10;  region         &#61; string&#10;  vcpu_count     &#61; optional&#40;number, 4&#41;&#10;  memory_bytes   &#61; optional&#40;number, 21474836480&#41;&#10;  subnetworks    &#61; list&#40;string&#41;&#10;  rebalance_mode &#61; optional&#40;string, &#34;NO_REBALANCE&#34;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [network_project_ids](variables.tf#L46) | List of project IDs where the subnets are located. | <code>list&#40;string&#41;</code> | ✓ |  |
| [project_id](variables.tf#L18) | The ID of the Google Cloud project where the Kafka cluster will be deployed. | <code>string</code> | ✓ |  |
| [labels](variables.tf#L40) | Additional labels for the Kafka cluster. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [topics](variables.tf#L51) | The list of topics to create in the Kafka cluster. | <code title="list&#40;object&#40;&#123;&#10;  topic_id           &#61; string&#10;  partition_count    &#61; optional&#40;number, 3&#41;&#10;  replication_factor &#61; optional&#40;number, 1&#41;&#10;  configs            &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;">list&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#91;&#93;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [kafka_cluster_id](outputs.tf#L17) | The ID of the Kafka cluster. |  |
| [kafka_labels](outputs.tf#L27) | Labels applied to the Kafka cluster. |  |
| [kafka_region](outputs.tf#L22) | The region where the Kafka cluster is deployed. |  |
| [project_number](outputs.tf#L32) | The project number of the Kafka cluster. |  |

## Test

```hcl
module "test" {
  source = "./fabric/fast/project-templates/managed-kafka"
  kafka_config = {
    cluster_id   = "test-cluster"
    region       = "us-central1"
    vcpu_count   = 4
    memory_bytes = 21474836480
    subnetworks = [
      "projects/test-project/regions/us-central1/subnetworks/test-subnetwork"
    ]
    rebalance_mode = "AUTO_REBALANCE_ON_SCALE_UP"
  }
  project_id = "my-managed-kafka-project"
  network_project_ids = [
    "test-network-project"
  ]
  topics = [
    {
      topic_id           = "test-topic-1"
      partition_count    = 3
      replication_factor = 2
      configs = {
        "cleanup.policy" = "compact"
      }
    }
  ]
  labels = {
    environment = "test"
  }
}
# tftest skip
```
