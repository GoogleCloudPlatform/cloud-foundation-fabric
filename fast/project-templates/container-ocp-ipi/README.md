# Artifact Registry APT Remote Registries

This simple setup allows creating and configuring remote APT repositories, that can be used for instance package updates without the need for an Internet connection.

## Prerequisites

The [`project.yaml`](./project.yaml) file describes the project-level configuration needed in terms of API activation and IAM bindings.

If you are deploying this inside a FAST-enabled organization, the file can be lightly edited to match your configuration, and then used directly in the [project factory](../../stages/2-project-factory/).

This Terraform can of course be deployed using any pre-existing project. In that case use the YAML file to determine the configuration you need to set on the project:

- enable the APIs listed under `services`
- grant the permissions listed under `iam` to the principal running Terraform, either machine (service account) or human

## VPC-SC Integration

Access to upstream sources from inside a VPC-SC service perimeter [requires specific activation](https://cloud.google.com/artifact-registry/docs/repositories/remote-repo#vpc), which depends on a high-level IAM role on the VPC-SC policy.

Granting such a role to the identity running this setup (either machine or human) is not realistic, so the choice made here is to output the relevant command, so that a VPC-SC administrator can run it using the appropriate credentials. The [relevant Terraform resource](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/artifact_registry_vpcsc_config) can of course be used to automate this task when needed.

## Instance-level Access to the Repository

Instances that need access to the created registries require the `roles/artifactregistry.writer` role assigned to the instance service accounts. This can be automated via the `apt_remote_registries` variable described below, to create IAm bindings for each registry.

It's also possible (and maybe desirable) to grant the role at the project level, if access to multiple repositories is needed from the same set of principals. This needs of course to happen where the project is managed, for example in the project factory YAML file.

Once proper access has been configured, the `apt_configs` output can be used as a basis to configure the APT sources lists on each instance.

Instance need to have the `apt-transport-artifact-registry` package installed, which is served by the default internal repositories configured on GCE base images.

```bash
sudo apt install apt-transport-artifact-registry
```

## Variable Configuration

This is an example of running this stage. Note that the `apt_remote_registries` has a default value that can be used when no IAM is needed at the registry level, and the default set of remotes is fine.

```hcl
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
# tftest skip
```
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
