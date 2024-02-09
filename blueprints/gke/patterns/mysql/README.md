
# Highly Available MySQL cluster on GKE

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

Database admin password is generated in terraform and stored as a Kubernetes Secret.

`mysql-server` Pods are spread across different zones using `topologySpreadConstraints`  with `maxSkew` of 1, `minDomains` of 3 and Pod antiAffinity preventing the Pods to run on the same host. This permits running two nodes in one zone (but on different hosts) in case of one zone failure in 3-zoned region.

`mysql-router` Pods hava affinity to run in the same zones as `mysql-server` nodes and antiAffinity to run on the same host (required) or zone (preferred) as other `mysql-router` . With two instances of `mysql-router` this might result in 2 instances running in the same region

## Usage
### Prerequisites
* GKE cluster is already provisioned and access to it using `kubectl` is configured. You can use [autopilot-cluster](../autopilot-cluster) blueprint to create such cluster.
* kubectl configuration obtained either by `gcloud container clusters get-credentials` or `gcloud container fleet memberships get-credentials`
* Cluster node have access to Oracle images `mysql/mysql-server` and `mysql/mysql-router`
* Access to the cluster's API from where `terraform` is run either using GKE API endpoint of Fleet endpoint. [Autopilot-cluster](../autopilot-cluster) blueprint provisions and provides the link to Fleet endpoint.
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
