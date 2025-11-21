# Artifact Registry APT Remote Registries

This simple setup allows creating and configuring remote APT repositories, that can be used for instance package updates without the need for an Internet connection.

## Prerequisites

The [`project.yaml`](./project.yaml) file describes the project-level configuration needed in terms of API activation and IAM bindings.

If you are deploying this inside a FAST-enabled organization, the file can be lightly edited to match your configuration, and then used directly in the [project factory](../../stages/2-project-factory/).

This Terraform can of course be deployed using any pre-existing project. In that case use the YAML file to determine the configuration you need to set on the project:

- enable the APIs listed under `services`
- grant the permissions listed under `iam` to the principal running Terraform, either machine (service account) or human

## Notes

Create an instance and associate the `ocp-install` service account.

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [project_id](variables.tf#L56) | Project id where the registries will be created. | <code>string</code> | ✓ |  |
| [apt_remote_registries](variables.tf#L17) | Remote artifact registry configurations. | <code title="list&#40;object&#40;&#123;&#10;  path              &#61; string&#10;  writer_principals &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;&#125;&#41;&#41;">list&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code title="&#91;&#10;  &#123; path &#61; &#34;DEBIAN debian&#47;dists&#47;bookworm&#34; &#125;,&#10;  &#123; path &#61; &#34;DEBIAN debian-security&#47;dists&#47;bookworm-security&#34; &#125;&#10;&#93;">&#91;&#8230;&#93;</code> |
| [location](variables.tf#L43) | Region where the registries will be created. | <code>string</code> |  | <code>&#34;europe-west8&#34;</code> |
| [name](variables.tf#L49) | Prefix used for all resource names. | <code>string</code> |  | <code>&#34;apt-remote&#34;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [apt_configs](outputs.tf#L23) | APT configurations for remote registries. |  |
| [vpcsc_command](outputs.tf#L33) | Command to allow egress to remotes from inside a perimeter. |  |
<!-- END TFDOC -->

## Test

```hcl
module "test" {
  source     = "./fabric/fast/project-templates/os-apt-registries"
  project_id = "my-project"
  location   = "europe-west3"
  apt_remote_registries = [
    { path = "DEBIAN debian/dists/bookworm" },
    {
      path = "DEBIAN debian-security/dists/bookworm-security"
      # grant specific access permissions to this registry
      writer_principals = [
        "serviceAccount:vm-default@prod-proj-0.iam.gserviceaccount.com"
      ]
    }
  ]
}
# tftest modules=3 resources=4
```
