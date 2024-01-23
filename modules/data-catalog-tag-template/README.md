# Google Cloud Data Catalog Tag Template Module

This module allows managing [Data Catalog Tag Templates](https://cloud.google.com/data-catalog/docs/tags-and-tag-templates).

## TODO

- [ ] IAM support at resource level

## Examples

### Simple Tag Template

```hcl
module "data-catalog-tag-template" {
  source     = "./fabric/modules/data-catalog-tag-template"
  project_id = "my-project"
  tag_templates = {
    demo_var = {
      tag_template_id = "my_template"
      region          = "europe-west1"
      display_name    = "Demo Tag Template"
      fields = [
        {
          field_id     = "source"
          display_name = "Source of data asset"
          type = {
            primitive_type = "STRING"
          }
          is_required = true
        }
      ]
    }
  }
}
# tftest modules=1 resources=5 inventory=simple.yaml
```

### Factory

Similarly to other modules, a rules factory (see [Resource Factories](../../blueprints/factories/)) is also included here to allow tag template management via descriptive configuration files.

Factory configuration is via one optional attributes in the `factory_config_path` variable specifying the path where tag template files are stored.

Factory tag templates are merged with rules declared in code, with the latter taking precedence where both use the same key.

The name of the file will be used as `tag_template_id` field.

This is an example of a simple factory:

```hcl
module "firewall-policy" {
  source    = "./fabric/modules/data-catalog-tag-template"
  project_id = "my-project"
  tag_templates = {
    demo_var = {
      tag_template_id = "my_template"
      region          = "europe-west1"
      display_name    = "Demo Tag Template"
      fields = [
        {
          field_id     = "source"
          display_name = "Source of data asset"
          type = {
            primitive_type = "STRING"
          }
          is_required = true
        }
      ]
    }
  }
  factory_config_path = "data"
}
# tftest modules=1 resources=6 files=demo_tag
```

```yaml
# tftest-file id=demo_tag path=configs/demo.yaml

region: europe-west2
display_name: Demo Tag Template
fields:
  - field_id: source
    display_name: Source of data asset
    type:
      primitive_type: STRING
    is_required: true
  - field_id: pii_type
    display_name: PII type
    type:
      enum_type:
        - allowed_values:
            display_name: EMAIL
        - allowed_values:
            display_name: SOCIAL SECURITY NUMBER
        - allowed_values:
            display_name: NONE
```
<!-- BEGIN TFDOC -->
<!-- END TFDOC -->
