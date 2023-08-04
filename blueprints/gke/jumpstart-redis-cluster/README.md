# Redis cluster on GKE

- [documentation guide](https://cloud.google.com/kubernetes-engine/docs/tutorials/upgrading-stateful-workload)

## Potential changes

- [ ] Split in 2 stages:
  - [ ] Base infra (cluster, vpc, etc)
    - [ ] Allow switching between standard and autopilot
    - [ ] Expose gke options needed for the jumpstarts (maintnance window, versions, etc.)
  - [ ] Workload (redis, etc)
    - [ ] support external kubeconfig via variable, and skip fleet resources if a kubeconfig is specified

## Prerequisites

- if an external fleet project is used and the remote artifact registry is being created, the fleet project needs the AR service enabled

## Test scenarios

project creation with own vpc
project creation in different project with svpc attachment

### Existing cluster

```hcl
cluster_name = "test-00"
project_id   = "tf-playground-svpc-gke-fleet"
```

### Create cluster, use shared VPC

```hcl
create_config = {
  cluster = {
    master_ipv4_cidr_block = "172.16.20.16/28"
    vpc = {
      id        = "projects/ldj-dev-net-spoke-0/global/networks/dev-spoke-0"
      subnet_id = "projects/ldj-dev-net-spoke-0/regions/europe-west8/subnetworks/gke"
    }
  }
}
cluster_name = "test-01"
project_id   = "tf-playground-svpc-gke-fleet"
```

### Create cluster, create VPC

```hcl
create_config = {
  cluster = {}
  vpc = {}
}
cluster_name = "test-01"
project_id   = "tf-playground-svpc-gke-fleet"
```
