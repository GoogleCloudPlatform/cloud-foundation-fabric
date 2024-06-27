# Batch Processing on GKE with Kueue

<!-- BEGIN TOC -->
- [Introduction](#introduction)
- [Requirements](#requirements)
- [Cluster authentication](#cluster-authentication)
- [Kueue Configuration](#kueue-configuration)
- [Sample Configuration](#sample-configuration)
- [Variables](#variables)
<!-- END TOC -->

## Introduction
<a href="https://shell.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/GoogleCloudPlatform/cloud-foundation-fabric.git&cloudshell_tutorial=batch/tutorial.md&cloudshell_git_branch=master&cloudshell_workspace=blueprints/gke/patterns&show=ide%2Cterminal">
<img width="200px" src="../../../../assets/images/cloud-shell-button.png">
</a>

This blueprint shows how to deploy a batch system using [Kueue](https://kueue.sigs.k8s.io/docs/overview/) to perform job queuing on Google Kubernetes Engine (GKE) using Terraform.

Kueue is a Cloud Native Job scheduler that works with the default Kubernetes scheduler, the Job controller, and the cluster autoscaler to provide an end-to-end batch system. Kueue implements Job queueing, deciding when Jobs should wait and when they should start, based on quotas and a hierarchy for sharing resources fairly among teams.


## Requirements

This blueprint assumes the GKE cluster already exists. We recommend using the accompanying [Autopilot Cluster Pattern](../autopilot-cluster) to deploy a cluster according to Google's best practices. Once you have the cluster up-and-running, you can use this blueprint to deploy Kueue in it.

The Kueue manifests use container images hosted by registry.k8s.io, which means that the subnet where the GKE cluster is deployed needs to have Internet connectivity to download the images. If you're using the provided [Autopilot Cluster Pattern](../autopilot-cluster), you can set the `enable_cloud_nat` option of the `vpc_create` variable.

## Cluster authentication
Once you have a cluster with Internet connectivity, create a `terraform.tfvars` and setup the `credentials_config` variable. We recommend using Anthos Fleet to simplify accessing the control plane.

## Kueue Configuration

Only two variables are available to control Kueue's configuration:
- `teams_namespaces` which controls the namespaces used by different teams to run jobs.
- `kueue_namespace` which controls the namespace to deploy Kueue's own resources.

Any other configuration can be applied by directly modifying the YAML manifests under the [manifest-templates](manifest-templates) directory.

## Sample Configuration

The following template as a starting point for your terraform.tfvars
```tfvars
credentials_config = {
  kubeconfig = {
    path = "~/.kube/config"
  }
}
teams_namespaces = [
  "team-a",
  "team-b"
]
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [credentials_config](variables.tf#L17) | Configure how Terraform authenticates to the cluster. | <code title="object&#40;&#123;&#10;  fleet_host &#61; optional&#40;string&#41;&#10;  kubeconfig &#61; optional&#40;object&#40;&#123;&#10;    context &#61; optional&#40;string&#41;&#10;    path    &#61; optional&#40;string, &#34;&#126;&#47;.kube&#47;config&#34;&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [kueue_namespace](variables.tf#L36) | Namespaces of the teams running jobs in the clusters. | <code>string</code> |  | <code>&#34;kueue-system&#34;</code> |
| [team_namespaces](variables.tf#L43) | Namespaces of the teams running jobs in the clusters. | <code>list&#40;string&#41;</code> |  | <code title="&#91;&#10;  &#34;team-a&#34;,&#10;  &#34;team-b&#34;&#10;&#93;">&#91;&#8230;&#93;</code> |
| [templates_path](variables.tf#L53) | Path where manifest templates will be read from. Set to null to use the default manifests. | <code>string</code> |  | <code>null</code> |
<!-- END TFDOC -->
