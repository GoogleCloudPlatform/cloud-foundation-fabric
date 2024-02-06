# Google Cloud Source Repository Module

This module allows managing a single Cloud Source Repository, including IAM bindings and basic Cloud Build triggers.

<!-- BEGIN TOC -->
- [Examples](#examples)
  - [Repository with IAM](#repository-with-iam)
  - [Repository with Cloud Build trigger](#repository-with-cloud-build-trigger)
- [Files](#files)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Examples

### Repository with IAM

```hcl
module "repo" {
  source     = "./fabric/modules/source-repository"
  project_id = "my-project"
  name       = "my-repo"
  iam = {
    "roles/source.reader" = ["user:foo@example.com"]
  }
  iam_bindings_additive = {
    am1-reader = {
      member = "user:am1@example.com"
      role   = "roles/source.reader"
    }
  }
}
# tftest modules=1 resources=3 inventory=simple.yaml
```

### Repository with Cloud Build trigger

```hcl
module "repo" {
  source     = "./fabric/modules/source-repository"
  project_id = "my-project"
  name       = "my-repo"
  triggers = {
    foo = {
      filename        = "ci/workflow-foo.yaml"
      included_files  = ["**/*tf"]
      service_account = null
      substitutions = {
        BAR = 1
      }
      template = {
        branch_name = "main"
        project_id  = null
        tag_name    = null
      }
    }
  }
}
# tftest modules=1 resources=2 inventory=trigger.yaml
```

<!-- TFDOC OPTS files:1 -->
<!-- BEGIN TFDOC -->
## Files

| name | description | resources |
|---|---|---|
| [iam.tf](./iam.tf) | IAM resources. | <code>google_sourcerepo_repository_iam_binding</code> · <code>google_sourcerepo_repository_iam_member</code> |
| [main.tf](./main.tf) | Module-level locals and resources. | <code>google_cloudbuild_trigger</code> · <code>google_sourcerepo_repository</code> |
| [outputs.tf](./outputs.tf) | Module outputs. |  |
| [variables.tf](./variables.tf) | Module variables. |  |
| [versions.tf](./versions.tf) | Version pins. |  |

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L61) | Repository name. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L66) | Project used for resources. | <code>string</code> | ✓ |  |
| [group_iam](variables.tf#L17) | Authoritative IAM binding for organization groups, in {GROUP_EMAIL => [ROLES]} format. Group emails need to be static. Can be used in combination with the `iam` variable. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam](variables.tf#L24) | IAM bindings in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings](variables.tf#L31) | Authoritative IAM bindings in {KEY => {role = ROLE, members = [], condition = {}}}. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  members &#61; list&#40;string&#41;&#10;  role    &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings_additive](variables.tf#L46) | Individual additive IAM bindings. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  member &#61; string&#10;  role   &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [triggers](variables.tf#L71) | Cloud Build triggers. | <code title="map&#40;object&#40;&#123;&#10;  filename        &#61; string&#10;  included_files  &#61; list&#40;string&#41;&#10;  service_account &#61; string&#10;  substitutions   &#61; map&#40;string&#41;&#10;  template &#61; object&#40;&#123;&#10;    branch_name &#61; string&#10;    project_id  &#61; string&#10;    tag_name    &#61; string&#10;  &#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [id](outputs.tf#L17) | Fully qualified repository id. |  |
| [name](outputs.tf#L22) | Repository name. |  |
| [url](outputs.tf#L27) | Repository URL. |  |
<!-- END TFDOC -->
