# GKE Jumpstart Infrastructure

<!-- BEGIN TOC -->
<!-- END TOC -->

## Examples

### Existing Cluster with Local Fleet

```hcl
module "jumpstart-0" {
  source       = "./fabric/blueprints/gke/jumpstart/jumpstart-0-infra/"
  cluster_name = "test-0"
  project_id   = "my-prj"
}
# tftest modules=1 resources=1
```
