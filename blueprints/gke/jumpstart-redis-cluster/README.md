# Redis cluster on GKE

- [documentation guide](https://cloud.google.com/kubernetes-engine/docs/tutorials/upgrading-stateful-workload)

## Potential changes

- [ ] optionally support external kubeconfig via variable, and skip fleet resources if a kubeconfig is specified
- [ ] try using the fleet membership project id instead of number in the kubernetes provider configuration, if that works we can use the fleet membership `id` directly
- [ ] Use Gateway to expose the service? it's a cluster with a headles service so maybe not?
- [ ] for Docker pull access
  - [ ] optionally create Cloud NAT for local VPCs
  - [ ] optionally specify and [configure a proxy](https://samos-it.com/posts/gke-docker-registry-http-proxy.html) for Shared VPC scenarios (Shared VPC might already have Cloud NAT or similar egress)

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
