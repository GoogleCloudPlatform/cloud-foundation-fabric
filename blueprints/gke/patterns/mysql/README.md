TODO:
- use static IP address if provided
- MySQL password as variable or automatically generated?
     - provide either Secret Manager or generate password and give output
      - use init container (https://kubernetes.io/docs/concepts/workloads/pods/init-containers/) that runs gcloud to fetch secret into the file
      - use common volume to share the file between init and normal container
      - use workload identity federation https://cloud.google.com/kubernetes-engine/docs/tutorials/workload-identity-secrets to grant pods access to secret
  - otherwise use standard GKE secrets

- consider creation of MySQL Router after cluster is setup (to prevent misconfiguration of the router if it is bootstrapped before configuration completes)

- permanent IP address for LoadBalancer / DNS name?
  - not needed?

- should the Job that did the setup be removed in the end?

Other reading:
* https://dev.mysql.com/doc/mysql-operator/en/mysql-operator-introduction.html


Caveats:
* db cluster resize is not properly handled by scripts (changing number of cluster members) 
* resizing the cluster requires manually adding new members to the cluster / removing members. Adding can be done by rerun of the configuration Job 
* GKE may schedule the 2 pods within the same zone of 3-pod-cluster, which is undesirable for a long run TODO: (should add anti-affinity to not allow pods to run in the same zone?)
* GKE may schedule 2 `mysql-router` in the same zone TODO: (should add anti-affinity to not allow pods to run in the same zone?)


## Architecture
MySQL cluster is exposed using Regional Internal TCP Passthrough Load Balancer either on random or on provided static IP address. Services are listening on four different ports depending on protocol and intended usage:
* 6446 - read/write access using MySQL protocol (targets primary instance)
* 6447 - read-only access using MySQL protocol (targets any instance)
* 64460 - read/write access using MySQLx protocol (targets primary instance)
* 64470 - read-only access using MySQLx protocol (targets any instance)

Behind Load Balancer there are pods (by default - 2 pods) running MySQL router image that are responsible to route the traffic to proper MySQL cluster member. Router learns about MySQL cluster topology by contacting any MySQL server pod using `mysql-bootstrap` ClusterIP Service during startup and checks periodically for any changes in topology. 

MySQL instances are provisioned using StatefulSet and their Pod DNS identity is provided by Headless Service `mysql`. Those DNS names (`dbc1-${index}.mysql.${namespace}.svc.cluster.local`) are used when configuring the cluster and by MySQL router when connecting to desired instance. By default, there are 3 instances provisioned, which is required minimum to obtain highly available solution. Each instance in StatefulSet attaches Physical Volume to store database which persists removal of the Pod or changing the number of instances. These Physical Volumes are kept even when StatefulSet is removed and require manual removal.  

Database admin password is stored either as a Kubernetes Secret or accessed from GCP Secret Manager.

`mysql-server` Pods are spread across different zones using `topologySpreadConstraints`  with `maxSkew` of 1, `minDomains` of 3 and Pod antiAffinity preventing the Pods to run on the same host. This permits running two nodes in one zone (but on different hosts) in case of one zone failure in 3-zoned region.

`mysql-router` Pods hava affinity to run in the same zones as `mysql-server` nodes and antiAffinity to run on the same host (required) or zone (preferred) as other `mysql-router` . With two instances of `mysql-router` this might result in 2 instances running in the same region

## Usage
### Prerequisites
* GKE cluster is already provisioned and access to it using `kubectl` is configured. You can use [infra](../jumpstart-0-infra) blueprint to create such cluster.
* kubectl configuration obtained either by `gcloud container clusters get-credentials` or `gcloud container fleet memberships get-credentials`
* Cluster node have access to Docker Hub images `mysql/mysql-server` and `mysql/mysql-router` or [remote repository](https://cloud.google.com/artifact-registry/docs/repositories/remote-repo) is configured. [infra](../jumpstart-0-infra) blueprint also provides that
* Access to the cluster's API from where `terraform` is run either using GKE API endpoint of Fleet endpoint ([infra](../jumpstart-0-infra) blueprint provisions and provides the link to Fleet endpoint)
* (optional) Secret Manager instance, secrets storing MySQL admin password and Service Account with permission to access these secrets
* (optional) static IP address to be used by LoadBalancer that exposes MySQL

## Examples
### Default MySQL cluster on GKE with Docker Hub connectivity using Fleet Connection endpoint
```hcl
credentials_config = {
  fleet_host = "https://connectgateway.googleapis.com/v1/projects/.../locations/global/gkeMemberships/..."  # provided by ../jumpstart-0-infra blueprint
}

# tftest skip
```

### Customized MySQL cluster using Remote Repository and Fleet Connection endpoint
```hcl
credentials_config = {
  fleet_host = "https://connectgateway.googleapis.com/v1/projects/.../locations/global/gkeMemberships/..."  # provided by ../jumpstart-0-infra blueprint
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
  fleet_host = "https://connectgateway.googleapis.com/v1/projects/.../locations/global/gkeMemberships/..."  # provided by ../jumpstart-0-infra blueprint
}
mysql_config = {
  ip_address = "10.0.0.2"
}
# tftest skip
```



### Default cluster using passwords stored in Secret Manager

```hcl
credentials_config = {
  fleet_host = "https://connectgateway.googleapis.com/v1/projects/.../locations/global/gkeMemberships/..."  # provided by ../jumpstart-0-infra blueprint
}

# tftest skip
```

