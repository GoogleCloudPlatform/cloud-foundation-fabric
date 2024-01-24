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
# tftest modules=1 resources=1
```

### Tag Template with IAM

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
  iam = {
    "roles/datacatalog.tagTemplateOwner" = ["group:data-governance@example.com"]
    "roles/datacatalog.tagTemplateUser"  = ["group:data-product-eng@example.com"]
  }
}
# tftest modules=1 resources=3
```

### Factory

Similarly to other modules, a rules factory (see [Resource Factories](../../blueprints/factories/)) is also included here to allow tag template management via descriptive configuration files.

Factory configuration is via one optional attributes in the `factory_config_path` variable specifying the path where tag template files are stored.

Factory tag templates are merged with rules declared in code, with the latter taking precedence where both use the same key.

The name of the file will be used as `tag_template_id` field.

This is an example of a simple factory:

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
  factory_config_path = "data"
}
# tftest modules=1 resources=1 files=demo_tag
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
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [project_id](variables.tf#L23) | Id of the project where Tag Templates will be created. | <code>string</code> | ✓ |  |
| [factory_config_path](variables.tf#L17) | Path to data files and folders that enable factory functionality. | <code>string</code> |  | <code>&#34;data&#34;</code> |
| [tag_templates](variables.tf#L28) | Tag templates definitions in the form {TAG_TEMPLATE_ID => TEMPLATE_DEFINITION}. | <code title="map&#40;object&#40;&#123;&#10;  display_name &#61; optional&#40;string&#41;&#10;  force_delete &#61; optional&#40;bool, false&#41;&#10;  region       &#61; string&#10;  fields &#61; list&#40;object&#40;&#123;&#10;    field_id     &#61; string&#10;    display_name &#61; optional&#40;string&#41;&#10;    description  &#61; optional&#40;string&#41;&#10;    type &#61; object&#40;&#123;&#10;      primitive_type &#61; optional&#40;string&#41;&#10;      enum_type &#61; optional&#40;list&#40;object&#40;&#123;&#10;        allowed_values &#61; object&#40;&#123;&#10;          display_name &#61; string&#10;        &#125;&#41;&#10;      &#125;&#41;&#41;, null&#41;&#10;    &#125;&#41;&#10;    is_required &#61; optional&#40;bool, false&#41;&#10;    order       &#61; optional&#40;number&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [data_catalog_tag_template_ids](outputs.tf#L17) | Data catalog tag template ids. |  |
| [data_catalog_tag_templates](outputs.tf#L22) | Data catalog tag templates. |  |
<!-- END TFDOC -->
