# GKE Jumpstart Infrastructure

<!-- BEGIN TOC -->
<!-- END TOC -->

## Examples

### Existing Cluster with Local Fleet

```hcl
module "jumpstart-0" {
  source       = "./fabric/blueprints/gke/jumpstart/jumpstart-0-infra/"
  project_id   = "tf-playground-svpc-gke-fleet"
  cluster_name = "test-00"
}
# tftest modules=1 resources=1
```

### New Cluster with Local Fleet

```hcl
module "jumpstart-0" {
  source       = "./fabric/blueprints/gke/jumpstart/jumpstart-0-infra/"
  project_id   = "tf-playground-svpc-gke-fleet"
  cluster_name = "test-01"
  create_cluster = {
    vpc = {
      id =        "projects/ldj-dev-net-spoke-0/global/networks/dev-spoke-0"
      subnet_id = "projects/ldj-dev-net-spoke-0/regions/europe-west8/subnetworks/gke"
    }
  }
}
# tftest modules=1 resources=1
```
  