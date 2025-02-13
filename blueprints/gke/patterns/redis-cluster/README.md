# Highly Available Redis Cluster on GKE

<!-- BEGIN TOC -->
- [Introduction](#introduction)
- [Requirements](#requirements)
- [Cluster authentication](#cluster-authentication)
- [Redis Cluster Configuration](#redis-cluster-configuration)
- [Sample Configuration](#sample-configuration)
- [Variables](#variables)
<!-- END TOC -->

## Introduction
<a href="https://shell.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/GoogleCloudPlatform/cloud-foundation-fabric.git&cloudshell_tutorial=redis-cluster/tutorial.md&cloudshell_git_branch=master&cloudshell_workspace=blueprints/gke/patterns&show=ide%2Cterminal">
<img width="200px" src="../../../../assets/images/cloud-shell-button.png">
</a>

This blueprint shows how to deploy a highly available Redis cluster on GKE following Google's recommended practices for creating a stateful application.

## Requirements

This blueprint assumes the GKE cluster already exists. We recommend using the accompanying [Autopilot Cluster Pattern](../autopilot-cluster) to deploy a cluster according to Google's best practices. Once you have the cluster up-and-running, you can use this blueprint to deploy Kueue in it.

## Cluster authentication
Once you have a cluster with, create a `terraform.tfvars` and setup the `credentials_config` variable. We recommend using Anthos Fleet to simplify accessing the control plane.

## Redis Cluster Configuration

This template exposes several variables to configure the Redis cluster:
- `namespace` which controls the namespace used to deploy the Redis instances
- `image` to change the container image used by the Redis cluster. Defaults to `redis:6.2` (i.e. the official Redis image, version 6.2)
- `stateful_config` to customize the configuration of the Redis' stateful set configuration. The default configuration deploys a 6-node cluster with requests for 1 CPU, 1Gi of RAM and a 10Gi volume.

Any other configuration can be applied by directly modifying the YAML manifests under the [manifest-templates](manifest-templates) directory.

## Sample Configuration

The following template as a starting point for your terraform.tfvars
```tfvars
credentials_config = {
  kubeconfig = {
    path = "~/.kube/config"
  }
}
statefulset_config = {
  replicas = 8
  resource_requests = {
    cpo    = "2"
    memory = "2Gi"
  }
}
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [credentials_config](variables.tf#L17) | Configure how Terraform authenticates to the cluster. | <code title="object&#40;&#123;&#10;  fleet_host &#61; optional&#40;string&#41;&#10;  kubeconfig &#61; optional&#40;object&#40;&#123;&#10;    context &#61; optional&#40;string&#41;&#10;    path    &#61; optional&#40;string, &#34;&#126;&#47;.kube&#47;config&#34;&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [image](variables.tf#L36) | Container image to use. | <code>string</code> |  | <code>&#34;redis:6.2&#34;</code> |
| [namespace](variables.tf#L43) | Namespace used for Redis cluster resources. | <code>string</code> |  | <code>&#34;redis&#34;</code> |
| [statefulset_config](variables.tf#L50) | Configure Redis cluster statefulset parameters. | <code title="object&#40;&#123;&#10;  replicas &#61; optional&#40;number, 6&#41;&#10;  resource_requests &#61; optional&#40;object&#40;&#123;&#10;    cpu    &#61; optional&#40;string, &#34;1&#34;&#41;&#10;    memory &#61; optional&#40;string, &#34;1Gi&#34;&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  volume_claim_size &#61; optional&#40;string, &#34;10Gi&#34;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [templates_path](variables.tf#L68) | Path where manifest templates will be read from. Set to null to use the default manifests. | <code>string</code> |  | <code>null</code> |
<!-- END TFDOC -->
