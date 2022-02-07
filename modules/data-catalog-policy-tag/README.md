# Data Catalog Module

## Examples

### Simple Taxonomy
```hcl

#TODO

# tftest modules=1 resources=4
```

### Simple Taxonomy with policy tags

```hcl

module "cmn-dc" {
  source     = "../../../modules/data-catalog"
  name       = "dc-tags"
  project_id = module.cmn-prj.project_id
  tags       = ["low", "medium", "high"]
}

# tftest modules=1 resources=4
```

### Simple Taxonomy with IAM binding

```hcl

module "cmn-dc" {
  source     = "../../../modules/data-catalog"
  name       = "dc-tags"
  project_id = module.cmn-prj.project_id
  tags       = ["low", "medium", "high"]
  iam = {
    "roles/datacatalog.categoryAdmin" = ["group:GROUP_NAME@example.com"]
  }
}

# tftest modules=1 resources=5
```
<!-- BEGIN TFDOC -->

<!-- END TFDOC -->

## TODO
- Support IAM at tag level.