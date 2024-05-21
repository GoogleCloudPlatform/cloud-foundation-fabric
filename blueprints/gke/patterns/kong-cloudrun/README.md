# Kong Gateway on GKE offloading to Cloud Run

<!-- BEGIN TOC -->
- [Introduction](#introduction)
- [Requirements](#requirements)
- [Kong Gateway Configuration](#kong-gateway-configuration)
- [Sample Configuration](#sample-configuration)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Introduction

This blueprint deploys the Kong API Gateway on GKE with a workload running on Cloud Run. Usually workloads will run on GKE together with the gateway, but some use cases may benefit from running on Cloud Run like handling spiky workloads or for cost optimization.

## Requirements

This blueprint assumes the GKE cluster already exists. We recommend using the accompanying [Autopilot Cluster Pattern](../autopilot-cluster) to deploy a cluster according to Google's best practices. Once you have the cluster up and running, you can use this blueprint to deploy Kong on it.

## Kong Gateway Configuration

This blueprint deploys Kong following the instructions in the [official documentation](https://docs.konghq.com/gateway/latest/install/kubernetes/proxy/). These instructions configure Kong Gateway to use separate control plane and data plane deployments. You can adjust this configuration by directly modifying the YAML manifests under the [manifest-templates](manifest-templates) directory.

The Cloud Run service is exposed behind an Internal Application Load Balancer to provide a custom domain and an HTTPS certificate to Kong. The LB certificate is managed through [Google Cloud Certificate Authority Service](https://cloud.google.com/certificate-authority-service/docs/ca-service-overview). The CA Service allows you to better integrate Kong with Google Cloud managing your own private PKI.

To ease deployment and use of this blueprint, a kubernetes job is created to automatically configure Kong via its _admin API_ to point to Cloud Run. Once deployed, Terraform will produce an output with the public IP of the Kong gateway. Simply point your browser to that IP to visit the web page offered by Cloud Run. For a production-ready installation please refer to the [official Kong Gateway documentation](https://docs.konghq.com/gateway/latest/).

## Sample Configuration

Use the following template as a starting point for your terraform.tfvars
```tfvars
credentials_config = {
  kubeconfig = {
    path = "~/.kube/config"
  }
}

prefix = "test"

service_project = {
  project_id = "kong-hello"
}
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [credentials_config](variables.tf#L36) | Configure how Terraform authenticates to the cluster. | <code title="object&#40;&#123;&#10;  fleet_host &#61; optional&#40;string&#41;&#10;  kubeconfig &#61; optional&#40;object&#40;&#123;&#10;    context &#61; optional&#40;string&#41;&#10;    path    &#61; optional&#40;string, &#34;&#126;&#47;.kube&#47;config&#34;&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [prefix](variables.tf#L74) | Prefix used for project names. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L83) | Host project with autopilot cluster. | <code>string</code> | ✓ |  |
| [service_project](variables.tf#L94) | Service project for Cloud Run service. | <code title="object&#40;&#123;&#10;  billing_account_id &#61; optional&#40;string&#41;&#10;  parent             &#61; optional&#40;string&#41;&#10;  project_id         &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [cloudrun_svcname](variables.tf#L17) | Name of the Cloud Run service. | <code>string</code> |  | <code>&#34;hello-kong&#34;</code> |
| [created_resources](variables.tf#L23) | Names of the resources created by autopilot cluster to be consumed here. | <code title="object&#40;&#123;&#10;  vpc_name    &#61; string&#10;  subnet_name &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  vpc_name    &#61; &#34;autopilot&#34;&#10;  subnet_name &#61; &#34;cluster-default&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [custom_domain](variables.tf#L55) | Custom domain for the Load Balancer. | <code>string</code> |  | <code>&#34;acme.org&#34;</code> |
| [image](variables.tf#L61) | Container image for Cloud Run services. | <code>string</code> |  | <code>&#34;us-docker.pkg.dev&#47;cloudrun&#47;container&#47;hello&#34;</code> |
| [namespace](variables.tf#L67) | Namespace used for Kong cluster resources. | <code>string</code> |  | <code>&#34;kong&#34;</code> |
| [region](variables.tf#L88) | Cloud region where resources will be deployed. | <code>string</code> |  | <code>&#34;europe-west1&#34;</code> |
| [templates_path](variables.tf#L108) | Path where manifest templates will be read from. Set to null to use the default manifests. | <code>string</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [kong_ip](outputs.tf#L17) | Kong API gateway IP. |  |
<!-- END TFDOC -->
