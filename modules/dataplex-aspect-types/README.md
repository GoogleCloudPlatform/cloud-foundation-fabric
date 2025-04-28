# Dataplex Aspect Types Module

This module allows managing [Dataplex Aspect Types](https://cloud.google.com/dataplex/docs/enrich-entries-metadata) and their associated IAM bindings via variables and YAML files defined via a resource factory.

The module manages Aspect Types for a single location in a single project. To manage them in different locations invoke the module multiple times, or use it with a `for_each` on locations/projects.

<!-- BEGIN TOC -->
- [Simple example](#simple-example)
- [Factory example](#factory-example)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Simple example

This example mirrors the one in the [`google_dataplex_aspect_type`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dataplex_aspect_type) resource documentation, but also shows how to manage IAM on the single aspect type. More types can of course be defined by just adding them to the `aspect_types` map.

```hcl
module "aspect-types" {
  source     = "./fabric/modules/dataplex-aspect-types"
  project_id = "test-project"
  # var.location defaults to "global"
  # location   = "global"
  aspect_types = {
    tf-test-template = {
      display_name = "Test template."
      iam = {
        "roles/dataplex.aspectTypeOwner" = ["group:data-owners@example.com"]
      }
      iam_bindings_additive = {
        user = {
          role   = "roles/dataplex.aspectTypeUser"
          member = "serviceAccount:sa-0@test-project.iam.gserviceaccount.com"
        }
      }
      metadata_template = <<END
      {
        "name": "tf-test-template",
        "type": "record",
        "recordFields": [
          {
            "name": "type",
            "type": "enum",
            "annotations": {
              "displayName": "Type",
              "description": "Specifies the type of view represented by the entry."
            },
            "index": 1,
            "constraints": {
              "required": true
            },
            "enumValues": [
              {
                "name": "VIEW",
                "index": 1
              }
            ]
          }
        ]
      }
      END
    }
  }
}
# tftest modules=1 resources=3
```

## Factory example

Aspect types can also be defined via a resource factory, where the file name will be used as the aspect type id. The resulting data is then internally combined with the `aspect_types` variable.

IAM attributes can leverage substitutions for principals, which need to be defined via the `factories_configs.context.iam_principals` variable as shown in the example below.

```hcl
module "aspect-types" {
  source     = "./fabric/modules/dataplex-aspect-types"
  project_id = "test-project"
  factories_config = {
    aspect_types = "data/aspect-types"
    context = {
      iam_principals = {
        test-sa = "serviceAccount:sa-0@test-project.iam.gserviceaccount.com"
      }
    }
  }
}
# tftest modules=1 resources=4 files=aspect-0,aspect-1
```

```yaml
display_name: "Test template 0."
iam:
  "roles/dataplex.aspectTypeOwner":
    - group:data-owners@example.com
metadata_template: |
  {
    "name": "tf-test-template-0",
    "type": "record",
    "recordFields": [
      {
        "name": "type",
        "type": "enum",
        "annotations": {
          "displayName": "Type",
          "description": "Specifies the type of view represented by the entry."
        },
        "index": 1,
        "constraints": {
          "required": true
        },
        "enumValues": [
          {
            "name": "VIEW",
            "index": 1
          }
        ]
      }
    ]
  }
# tftest-file id=aspect-0 path=data/aspect-types/aspect-0.yaml schema=aspect-type.schema.json
```

```yaml
display_name: "Test template 1."
iam_bindings_additive:
  user:
    role: roles/dataplex.aspectTypeUser
    member: test-sa
metadata_template: |
  {
    "name": "tf-test-template-1",
    "type": "record",
    "recordFields": [
      {
        "name": "type",
        "type": "enum",
        "annotations": {
          "displayName": "Type",
          "description": "Specifies the type of view represented by the entry."
        },
        "index": 1,
        "constraints": {
          "required": true
        },
        "enumValues": [
          {
            "name": "VIEW",
            "index": 1
          }
        ]
      }
    ]
  }
# tftest-file id=aspect-1 path=data/aspect-types/aspect-1.yaml schema=aspect-type.schema.json
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [project_id](variables.tf#L67) | Project id where resources will be created. | <code>string</code> | ✓ |  |
| [aspect_types](variables.tf#L17) | Aspect templates. Merged with those defined via the factory. | <code title="map&#40;object&#40;&#123;&#10;  description       &#61; optional&#40;string&#41;&#10;  display_name      &#61; optional&#40;string&#41;&#10;  labels            &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  metadata_template &#61; optional&#40;string&#41;&#10;  iam               &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings &#61; optional&#40;map&#40;object&#40;&#123;&#10;    members &#61; list&#40;string&#41;&#10;    role    &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings_additive &#61; optional&#40;map&#40;object&#40;&#123;&#10;    member &#61; string&#10;    role   &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [factories_config](variables.tf#L48) | Paths to folders for the optional factories. | <code title="object&#40;&#123;&#10;  aspect_types &#61; optional&#40;string&#41;&#10;  context &#61; optional&#40;object&#40;&#123;&#10;    iam_principals &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [location](variables.tf#L60) | Location for aspect types. | <code>string</code> |  | <code>&#34;global&#34;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [ids](outputs.tf#L17) | Aspect type IDs. |  |
| [names](outputs.tf#L29) | Aspect type names. |  |
| [timestamps](outputs.tf#L41) | Aspect type create and update timestamps. |  |
| [uids](outputs.tf#L56) | Aspect type gobally unique IDs. |  |
<!-- END TFDOC -->
