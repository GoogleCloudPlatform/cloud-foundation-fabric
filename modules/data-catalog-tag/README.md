# Google Cloud Data Catalog Tag Module

This module allows managing [Data Catalog Tag](https://cloud.google.com/data-catalog/docs/tags-and-tag-templates) on GCP resources such as BigQuery Datasets, Tables or columns.

## TODO

- Add support for entries different than Bigquery resources.

## Examples

### Dataset Tag

```hcl
module "data-catalog-tag" {
  source = "./fabric/modules/data-catalog-tag"
  tags = {
    "landing/countries" = {
      project_id = "project-data-product"
      parent     = "projects/project-data-product/datasets/landing"
      location   = "europe-west-1"
      template   = "projects/project-datagov/locations/europe-west1/tagTemplates/demo"
      fields = {
        source = "DB-1"
      }
    }
  }
}
# tftest modules=1 resources=1
```

### Table Tag

```hcl
module "data-catalog-tag" {
  source = "./fabric/modules/data-catalog-tag"
  tags = {
    "landing/countries" = {
      project_id = "project-data-product"
      parent     = "projects/project-data-product/datasets/landing/tables/countries"
      location   = "europe-west-1"
      template   = "projects/project-datagov/locations/europe-west1/tagTemplates/demo"
      fields = {
        source = "DB-1 Table-A"
      }
    }
  }
}
# tftest modules=1 resources=1
```

### Column Tag

```hcl
module "data-catalog-tag" {
  source = "./fabric/modules/data-catalog-tag"
  tags = {
    "landing/countries" = {
      project_id = "project-data-product"
      parent     = "projects/project-data-product/datasets/landing/tables/countries"
      column     = "country"
      location   = "europe-west-1"
      template   = "projects/project-datagov/locations/europe-west1/tagTemplates/demo"
      fields = {
        source = "DB-1 Table-A Column-B"
      }
    }
  }
}
# tftest modules=1 resources=1
```

### Factory

Similarly to other modules, a rules factory (see [Resource Factories](../../blueprints/factories/)) is also included here to allow tags management via descriptive configuration files.

Factory configuration is via one optional attributes in the `factory_config_path` variable specifying the path where tags files are stored.

Factory tags are merged with rules declared in code, with the latter taking precedence where both use the same key.

This is an example of a simple factory:

```hcl
module "data-catalog-tag" {
  source = "./fabric/modules/data-catalog-tag"
  tags = {
    "landing/countries" = {
      project_id = "project-data-product"
      parent     = "projects/project-data-product/datasets/landing/tables/countries"
      column     = "country"
      location   = "europe-west-1"
      template   = "projects/project-datagov/locations/europe-west1/tagTemplates/demo"
      fields = {
        source = "DB-1 Table-A Column-B"
      }
    }
  }
  factories_config = {
    tags = "data"
  }
}
# tftest modules=1 resources=2 files=demo_tag
```

```yaml
# tftest-file id=demo_tag path=data/tag_1.yaml

project_id: project-data-product
parent: projects/project-data-product/datasets/exposure
template: projects/project-datagov/locations/europe-west1/tagTemplates/test
fields:
  owner_email: example@example.com
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [factories_config](variables.tf#L17) | Paths to data files and folders that enable factory functionality. | <code title="object&#40;&#123;&#10;  tags &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [tags](variables.tf#L26) | Tags definitions in the form {TAG => TAG_DEFINITION}. | <code title="map&#40;object&#40;&#123;&#10;  project_id &#61; string&#10;  parent     &#61; string&#10;  column     &#61; optional&#40;string&#41;&#10;  location   &#61; string&#10;  template   &#61; string&#10;  fields     &#61; map&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [data_catalog_tag_ids](outputs.tf#L17) | Data catalog tag ids. |  |
<!-- END TFDOC -->
