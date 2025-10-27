# Cloud Workstations Cluster

This simple setup allows creating and configuring one Cloud Workstation Cluster, and an arbitrary number of workstation configurations and workstations via a dedicated factory.

## Prerequisites

The [`project.yaml`](./project.yaml) file describes the project-level configuration needed in terms of API activation and IAM bindings.

If you are deploying this inside a FAST-enabled organization, the file can be lightly edited to match your configuration, and then used directly in the [project factory](../../stages/2-project-factory/).

This Terraform can of course be deployed using any pre-existing project. In that case use the YAML file to determine the configuration you need to set on the project:

- enable the APIs listed under `services`
- grant the permissions listed under `iam` to the principal running Terraform, either machine (service account) or human

## VPC-SC Integration

This example assumes a private cluster is needed, and provisions a PSC Endpoint for private connectivity. For more details on private clusters and VPC-SC see [this documentation page](https://cloud.google.com/workstations/docs/configure-vpc-service-controls-private-clusters).

An additional egress policy is needed to allow monitoring traffic for the cluster to the tenant project on the Google side. The following snippet can be added to the egress policy factory in the VPC-SC stage, and edited so that project numbers match. It should of course also be enabled in the perimeter definition.

```yaml
from:
  identities:
    - serviceAccount:service-1234567890@gcp-sa-workstations.iam.gserviceaccount.com
  resources:
    - projects/3456789012
to:
  operations:
    - service_name: monitoring.googleapis.com
      method_selectors:
        - "*"
  resources:
    - projects/1234567890
```

## Additional Configuration Steps

The workstations are accessible via the PSC Endpoint, once a DNS record for the cluster hostname has been configured. The cluster hostname is available from this example's outputs.

## Variable Configuration

This is an example of running this stage. Note that the `apt_remote_registries` has a default value that can be used when no IAM is needed at the registry level, and the default set of remotes is fine.

```hcl
project_id = "my-project"
location   = "europe-west3"
network_config = {
  network              = "projects/ldj-prod-net-landing-0/global/networks/prod-landing-0"
  subnetwork           = "projects/ldj-prod-net-landing-0/regions/europe-west8/subnetworks/ws"
  psc_endpoint_address = "10.0.18.10"
}
# tftest skip
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [network_config](variables.tf#L72) | VPC and subnet for the cluster. | <code title="object&#40;&#123;&#10;  network              &#61; string&#10;  subnetwork           &#61; string&#10;  psc_endpoint_address &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [project_id](variables.tf#L92) | Project id where the cluster will be created. | <code>string</code> | ✓ |  |
| [annotations](variables.tf#L17) | Workstation cluster annotations. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [context](variables.tf#L23) | Context-specific interpolations. | <code title="object&#40;&#123;&#10;  condition_vars &#61; optional&#40;map&#40;map&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  custom_roles   &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  iam_principals &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  locations      &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  networks       &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  project_ids    &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  subnetworks    &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [display_name](variables.tf#L38) | Display name. | <code>string</code> |  | <code>null</code> |
| [domain](variables.tf#L44) | Domain. | <code>string</code> |  | <code>null</code> |
| [factories_config](variables.tf#L50) | Path to folder with YAML resource description data files. | <code title="object&#40;&#123;&#10;  workstation_configs &#61; optional&#40;string, &#34;data&#47;workstation-configs&#34;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [id](variables.tf#L59) | Workstation cluster ID. | <code>string</code> |  | <code>&#34;ws-cluster-0&#34;</code> |
| [labels](variables.tf#L66) | Workstation cluster labels. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [private_cluster_config](variables.tf#L82) | Private cluster config. | <code title="object&#40;&#123;&#10;  allowed_projects        &#61; optional&#40;list&#40;string&#41;&#41;&#10;  enable_private_endpoint &#61; optional&#40;bool, true&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [service_accounts](variables.tf#L98) | Project factory managed service accounts to populate context. | <code title="map&#40;object&#40;&#123;&#10;  email &#61; string&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [hostname](outputs.tf#L17) | Cluster hostname. |  |
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
