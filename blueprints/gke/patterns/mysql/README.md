# Highly Available MySQL cluster on GKE

<!-- BEGIN TOC -->
- [Architecture](#architecture)
- [Usage](#usage)
  - [Prerequisites](#prerequisites)
- [Examples](#examples)
  - [Default MySQL cluster on GKE with Docker Hub connectivity using Fleet Connection endpoint](#default-mysql-cluster-on-gke-with-docker-hub-connectivity-using-fleet-connection-endpoint)
  - [Customized MySQL cluster using Remote Repository and Fleet Connection endpoint](#customized-mysql-cluster-using-remote-repository-and-fleet-connection-endpoint)
  - [Default cluster using provided static IP address](#default-cluster-using-provided-static-ip-address)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

<a href="https://shell.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/GoogleCloudPlatform/cloud-foundation-fabric.git&cloudshell_tutorial=mysql/tutorial.md&cloudshell_git_branch=master&cloudshell_workspace=blueprints/gke/patterns&show=ide%2Cterminal">
<img width="200px" src="../../../../assets/images/cloud-shell-button.png">
</a>

## Architecture
MySQL cluster is exposed using Regional Internal TCP Passthrough Load Balancer either on random or on provided static IP address. Services are listening on four different ports depending on protocol and intended usage:
* 6446 - read/write access using MySQL protocol (targets primary instance)
* 6447 - read-only access using MySQL protocol (targets any instance)
* 64460 - read/write access using MySQLx protocol (targets primary instance)
* 64470 - read-only access using MySQLx protocol (targets any instance)

Behind Load Balancer there are pods (by default - 2 pods) running MySQL router image that are responsible to route the traffic to proper MySQL cluster member. Router learns about MySQL cluster topology by contacting any MySQL server pod using `mysql-bootstrap` ClusterIP Service during startup and checks periodically for any changes in topology. 

MySQL's instances are provisioned using StatefulSet and their Pod DNS identity is provided by Headless Service `mysql`. Those DNS names (`dbc1-${index}.mysql.${namespace}.svc.cluster.local`) are used when configuring the cluster and by MySQL router when connecting to desired instance. By default, there are 3 instances provisioned, which is required minimum to obtain highly available solution. Each instance in StatefulSet attaches Physical Volume to store database which persists removal of the Pod or changing the number of instances. These Physical Volumes are kept even when StatefulSet is removed and require manual removal.

The database admin password is generated in Terraform and stored as a Kubernetes Secret.

`mysql-server` Pods are spread across different zones using `topologySpreadConstraints`  with `maxSkew` of 1, `minDomains` of 3 and Pod antiAffinity preventing the Pods to run on the same host. This permits running two nodes in one zone (but on different hosts) in case of one zone failure in 3-zoned region.

`mysql-router` Pods have affinity to run in the same zones as `mysql-server` nodes and antiAffinity to run on the same host (required) or zone (preferred) as other `mysql-router` . With two instances of `mysql-router` this might result in 2 instances running in the same region

## Usage
### Prerequisites
* GKE cluster is already provisioned and access to it using `kubectl` is configured. You can use [autopilot-cluster](../autopilot-cluster) blueprint to create such cluster.
* kubectl configuration obtained either by `gcloud container clusters get-credentials` or `gcloud container fleet memberships get-credentials`
* Cluster node have access to Oracle images `mysql/mysql-server` and `mysql/mysql-router`
* Access to the cluster's API from where `terraform` is run either using GKE API endpoint of Fleet endpoint. [autopilot-cluster](../autopilot-cluster) blueprint provisions and provides the link to Fleet endpoint.
* (optional) static IP address to be used by LoadBalancer that exposes MySQL

## Examples
### Default MySQL cluster on GKE with Docker Hub connectivity using Fleet Connection endpoint
```hcl
credentials_config = {
  fleet_host = "https://connectgateway.googleapis.com/v1/projects/.../locations/global/gkeMemberships/..."  # provided by ../autopilot-cluster blueprint
}

# tftest skip
```

### Customized MySQL cluster using Remote Repository and Fleet Connection endpoint
```hcl
credentials_config = {
  fleet_host = "https://connectgateway.googleapis.com/v1/projects/.../locations/global/gkeMemberships/..."  # provided by ../autopilot-cluster blueprint
}

registry_path = "europe-west8-docker.pkg.dev/.../..."
mysql_config = {
  db_replicas = 8
  db_cpu           = "750m"
  db_memory        = "2Gi"
  db_database_size = "4Gi"
  router_replicas  = 3
  router_cpu       = "250m"
  router_memory    = "1Gi"
  version          = "8.0.30"
}

# tftest skip
```

### Default cluster using provided static IP address

```hcl
credentials_config = {
  fleet_host = "https://connectgateway.googleapis.com/v1/projects/.../locations/global/gkeMemberships/..."  # provided by ../autopilot-cluster blueprint
}
mysql_config = {
  ip_address = "10.0.0.2"
}
# tftest skip
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [created_resources](variables.tf#L17) | IDs of the resources created by autopilot cluster to be consumed here. | <code title="object&#40;&#123;&#10;  vpc_id    &#61; string&#10;  subnet_id &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [credentials_config](variables.tf#L26) | Configure how Terraform authenticates to the cluster. | <code title="object&#40;&#123;&#10;  fleet_host &#61; optional&#40;string&#41;&#10;  kubeconfig &#61; optional&#40;object&#40;&#123;&#10;    context &#61; optional&#40;string&#41;&#10;    path    &#61; optional&#40;string, &#34;&#126;&#47;.kube&#47;config&#34;&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [project_id](variables.tf#L69) | Project to deploy bastion host. | <code>string</code> | ✓ |  |
| [region](variables.tf#L74) | Region used for cluster and network resources. | <code>string</code> | ✓ |  |
| [mysql_config](variables.tf#L45) | Configure MySQL server and router instances. | <code title="object&#40;&#123;&#10;  db_cpu           &#61; optional&#40;string, &#34;500m&#34;&#41;&#10;  db_database_size &#61; optional&#40;string, &#34;10Gi&#34;&#41;&#10;  db_memory        &#61; optional&#40;string, &#34;1Gi&#34;&#41;&#10;  db_replicas      &#61; optional&#40;number, 3&#41;&#10;  ip_address       &#61; optional&#40;string&#41;&#10;  router_replicas  &#61; optional&#40;number, 2&#41; &#35; cannot be higher than number of the zones in region&#10;  router_cpu       &#61; optional&#40;string, &#34;500m&#34;&#41;&#10;  router_memory    &#61; optional&#40;string, &#34;2Gi&#34;&#41;&#10;  version          &#61; optional&#40;string, &#34;8.0.34&#34;&#41; &#35; latest is 8.0.34, originally was with 8.0.28 &#47; 8.0.27,&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [namespace](variables.tf#L62) | Namespace used for MySQL cluster resources. | <code>string</code> |  | <code>&#34;mysql1&#34;</code> |
| [registry_path](variables.tf#L79) | Repository path for images. Default is to use Docker Hub images. | <code>string</code> |  | <code>&#34;docker.io&#34;</code> |
| [templates_path](variables.tf#L86) | Path where manifest templates will be read from. Set to null to use the default manifests. | <code>string</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [mysql_password](outputs.tf#L16) | Password for the MySQL root user. | ✓ |
<!-- END TFDOC -->
