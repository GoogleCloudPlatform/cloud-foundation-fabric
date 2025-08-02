# Google Cloud Data Catalog Tag Template Module

This module allows managing [Data Catalog Tag Templates](https://cloud.google.com/data-catalog/docs/tags-and-tag-templates).

<!-- BEGIN TOC -->
- [Simple Tag Template](#simple-tag-template)
- [Tag Template with IAM](#tag-template-with-iam)
- [Factory](#factory)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Simple Tag Template

```hcl
module "data-catalog-tag-template" {
  source     = "./fabric/modules/data-catalog-tag-template"
  project_id = "my-project"
  region     = "europe-west1"
  tag_templates = {
    demo_var = {
      display_name = "Demo Tag Template"
      fields = {
        source = {
          display_name = "Source of data asset"
          is_required  = true
          type = {
            primitive_type = "STRING"
          }
        }
      }
    }
  }
}
# tftest modules=1 resources=1
```

## Tag Template with IAM

The module conforms to our standard IAM interface and implements the `iam`, `iam_bindings` and `iam_bindings_additive` variables.

```hcl
module "data-catalog-tag-template" {
  source     = "./fabric/modules/data-catalog-tag-template"
  project_id = "my-project"
  region     = "europe-west1"
  tag_templates = {
    demo_var = {
      display_name = "Demo Tag Template"
      is_required  = true
      fields = {
        source = {
          display_name = "Source of data asset"
          type = {
            primitive_type = "STRING"
          }
        }
      }
      iam = {
        "roles/datacatalog.tagTemplateOwner" = [
          "group:data-governance@example.com"
        ]
        "roles/datacatalog.tagTemplateUser" = [
          "group:data-product-eng@example.com"
        ]
      }
    }
  }
}
# tftest modules=1 resources=3
```

## Factory

Similarly to other modules, a rules factory is also included here to allow tag template management via descriptive configuration files.

Factory configuration is done via a single optional attribute in the `factory_config_path` variable specifying the path where tag template files are stored.

Factory tag templates are merged with rules declared in code, with the latter taking precedence if both use the same key.

The name of the file will be used as the `tag_template_id` field.

This is an example of a simple factory:

```hcl
module "data-catalog-tag-template" {
  source     = "./fabric/modules/data-catalog-tag-template"
  project_id = "my-project"
  region     = "europe-west1"
  tag_templates = {
    demo_var = {
      display_name = "Demo Tag Template"
      fields = {
        source = {
          display_name = "Source of data asset"
          is_required  = true
          type = {
            primitive_type = "STRING"
          }
        }
      }
    }
  }
  factories_config = {
    tag_templates = "data"
  }
}
# tftest modules=1 resources=2 files=demo_tag
```

```yaml
# tftest-file id=demo_tag path=data/demo.yaml

display_name: Demo Tag Template
fields:
  source:
      display_name: Source of data asset
      is_required: true
      type:
        primitive_type: STRING
  pii_type:
      display_name: PII type
      type:
        enum_type_values:
          - EMAIL
          - SOCIAL SECURITY NUMBER
          - NONE
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [project_id](variables.tf#L29) | Id of the project where Tag Templates will be created. | <code>string</code> | ✓ |  |
| [factories_config](variables.tf#L17) | Paths to data files and folders that enable factory functionality. | <code title="object&#40;&#123;&#10;  tag_templates &#61; optional&#40;string&#41;&#10;  context &#61; optional&#40;object&#40;&#123;&#10;    regions &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [region](variables.tf#L34) | Default region for tag templates. | <code>string</code> |  | <code>null</code> |
| [tag_templates](variables.tf#L40) | Tag templates definitions in the form {TAG_TEMPLATE_ID => TEMPLATE_DEFINITION}. | <code title="map&#40;object&#40;&#123;&#10;  display_name &#61; optional&#40;string&#41;&#10;  force_delete &#61; optional&#40;bool, false&#41;&#10;  region       &#61; optional&#40;string&#41;&#10;  fields &#61; map&#40;object&#40;&#123;&#10;    display_name &#61; optional&#40;string&#41;&#10;    description  &#61; optional&#40;string&#41;&#10;    is_required  &#61; optional&#40;bool, false&#41;&#10;    order        &#61; optional&#40;number&#41;&#10;    type &#61; object&#40;&#123;&#10;      primitive_type   &#61; optional&#40;string&#41;&#10;      enum_type_values &#61; optional&#40;list&#40;string&#41;&#41;&#10;    &#125;&#41;&#10;  &#125;&#41;&#41;&#10;  iam &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings &#61; optional&#40;map&#40;object&#40;&#123;&#10;    members &#61; list&#40;string&#41;&#10;    role    &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings_additive &#61; optional&#40;map&#40;object&#40;&#123;&#10;    member &#61; string&#10;    role   &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [data_catalog_tag_template_ids](outputs.tf#L17) | Data catalog tag template ids. |  |
| [data_catalog_tag_templates](outputs.tf#L25) | Data catalog tag templates. |  |
<!-- END TFDOC -->
