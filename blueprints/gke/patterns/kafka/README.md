# Highly Available Kafka on GKE

<!-- BEGIN TOC -->
- [Introduction](#introduction)
- [Requirements](#requirements)
- [Cluster authentication](#cluster-authentication)
- [Kafka Configuration](#kafka-configuration)
- [Sample Configuration](#sample-configuration)
- [Variables](#variables)
<!-- END TOC -->

## Introduction

<a href="https://shell.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/GoogleCloudPlatform/cloud-foundation-fabric.git&cloudshell_tutorial=kafka/tutorial.md&cloudshell_git_branch=master&cloudshell_workspace=blueprints/gke/patterns&show=ide%2Cterminal">
<img width="200px" src="../../../../assets/images/cloud-shell-button.png">
</a>

This blueprints shows how to a hihgly available Kafka instance on GKE using the Strimzi operator.

## Requirements

This blueprint assumes the GKE cluster already exists. We recommend using the accompanying [Autopilot Cluster Pattern](../autopilot-cluster) to deploy a cluster according to Google's best practices. Once you have the cluster up-and-running, you can use this blueprint to deploy Kafka in it.

The Kafka manifests will download , which means that the subnet where the GKE cluster is deployed needs to have Internet connectivity to download the images. If you're using the provided [Autopilot Cluster Pattern](../autopilot-cluster), you can set the `enable_cloud_nat` option of the `vpc_create` variable.

## Cluster authentication
Once you have a cluster with Internet connectivity, create a `terraform.tfvars` and setup the `credentials_config` variable. We recommend using Anthos Fleet to simplify accessing the control plane.

## Kafka Configuration

This template exposes several variables to configure the Kafka instance:
- `namespace` which controls the namespace used to deploy the Kafka instance
- `kafka_config` to customize the configuration of the Kafka instance. The default configuration deploys version 3.6.0 with 3 replicas, with a disk of 10Gi and 4096 MB of RAM.
- `zookeeper_config` to customize the configuration of the Zookeeper instance. The default configuration deploys 3 replicas, with a disk of 10Gi and 2048 MB of RAM.

Any other configuration can be applied by directly modifying the YAML manifests under the [manifest-templates](manifest-templates) directory.

## Sample Configuration

The following template as a starting point for your terraform.tfvars
```tfvars
credentials_config = {
  kubeconfig = {
    path = "~/.kube/config"
  }
}
kafka_config = {
  volume_claim_size = "15Gi"
  replicas          = 4
}

zookeeper_config = {
  volume_claim_size = "15Gi"
}
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [credentials_config](variables.tf#L17) | Configure how Terraform authenticates to the cluster. | <code title="object&#40;&#123;&#10;  fleet_host &#61; optional&#40;string&#41;&#10;  kubeconfig &#61; optional&#40;object&#40;&#123;&#10;    context &#61; optional&#40;string&#41;&#10;    path    &#61; optional&#40;string, &#34;&#126;&#47;.kube&#47;config&#34;&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [kafka_config](variables.tf#L36) | Configure Kafka cluster statefulset parameters. | <code title="object&#40;&#123;&#10;  replicas          &#61; optional&#40;number, 3&#41;&#10;  volume_claim_size &#61; optional&#40;string, &#34;10Gi&#34;&#41;&#10;  version           &#61; optional&#40;string, &#34;3.6.0&#34;&#41;&#10;  jvm_memory        &#61; optional&#40;string, &#34;4096m&#34;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [namespace](variables.tf#L48) | Namespace used for Redis cluster resources. | <code>string</code> |  | <code>&#34;kafka&#34;</code> |
| [templates_path](variables.tf#L55) | Path where manifest templates will be read from. Set to null to use the default manifests. | <code>string</code> |  | <code>null</code> |
| [zookeeper_config](variables.tf#L61) | Configure Zookeper cluster statefulset parameters. | <code title="object&#40;&#123;&#10;  replicas          &#61; optional&#40;number, 3&#41;&#10;  volume_claim_size &#61; optional&#40;string, &#34;10Gi&#34;&#41;&#10;  jvm_memory        &#61; optional&#40;string, &#34;2048m&#34;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
<!-- END TFDOC -->
