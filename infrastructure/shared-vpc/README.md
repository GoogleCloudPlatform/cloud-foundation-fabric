# Shared VPC sample

This sample creates a basic [Shared VPC](https://cloud.google.com/vpc/docs/shared-vpc) infrastructure, where two service projects are connected to separate subnets, and the host project exposes Cloud DNS and Cloud KMS as centralized services. The service projects are slightly different, as they are meant to illustrate the IAM-level differences that need to be taken into account when sharing subnets for GCE or GKE.

The purpose of this sample is showing how to wire different [Cloud Foundation Fabric](https://github.com/search?q=topic%3Acft-fabric+org%3Aterraform-google-modules&type=Repositories) modules to create Shared VPC infrastructures, and as such it is meant to be used for prototyping, or to experiment with networking configurations. Additional best practices and security considerations need to be taken into account for real world usage (eg removal of default service accounts, disabling of external IPs, firewall design, etc).

![High-level diagram](diagram.png "High-level diagram")

## Managed resources and services

This sample creates several distinct groups of resources:

- three projects (Shared VPC host and two service projects)
- VPC-level resources (VPC, subnets, firewall rules, etc.) in the host project
- one internal Cloud DNS zone in the host project
- one Cloud KMS keyring with one key in the host project
- IAM roles to wire all the above resource together
- one test instance in each project, with their associated DNS records

## Test resources

A set of test resources are included for convenience, as they facilitate experimenting with different networking configurations (firewall rules, external connectivity via VPN, etc.). They are encapsulated in the `test-resources.tf` file, and can be safely removed as a single unit.

SSH access to instances is configured via [OS Login](https://cloud.google.com/compute/docs/oslogin/), except for the GKE project instance since [GKE nodes do not support OS Login](https://cloud.google.com/compute/docs/instances/managing-instance-access#limitations). To access the GKe instance, use a SSH key set at the project or instance level. External access is allowed via the default SSH rule created by the firewall module, and corresponding `ssh` tags on the instances.

The GCE instance is somewhat special, as it's configured to run a containerized MySQL server using the [`cos-mysql` module](https://github.com/terraform-google-modules/terraform-google-container-vm/tree/master/modules/cos-mysql), to show a practical example of using this module with KMS encryption for its secret, and to demonstrate how to define a custom firewall rule in the firewall module.

The networking and GKE instances have `dig` and the `mysql` client installed via startup scripts, so that tests can be run as soon as they are created.

## Destroying

There's a minor glitch that can surface running `terraform destroy`, with a simple workaround. The glitch is due to a delay between the API reporting service project removal from the Shared VPC as successful (`google_compute_shared_vpc_service_project` resources destroyed), and the Shared VPC resource being aligned with that event. This results in an error that prevents disabling the Shared VPC feature: `Error disabling Shared VPC Host [...] Cannot disable project as a shared VPC host because it has active service projects.`. The workaround is to run `terraform destroy` again after a few seconds, giving the Shared VPC resource time to be in sync with service project removal.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| billing\_account\_id | Billing account id used as default for new projects. | string | n/a | yes |
| kms\_keyring\_location | Location used for the KMS keyring. | string | `"europe"` | no |
| kms\_keyring\_name | Name used for the KMS keyring. | string | `"svpc-example"` | no |
| oslogin\_admins\_gce | GCE project oslogin admin members, in IAM format. | list | `<list>` | no |
| oslogin\_users\_gce | GCE project oslogin user members, in IAM format. | list | `<list>` | no |
| owners\_gce | GCE project owners, in IAM format. | list | `<list>` | no |
| owners\_gke | GKE project owners, in IAM format. | list | `<list>` | no |
| owners\_host | Host project owners, in IAM format. | list | `<list>` | no |
| prefix | Prefix used for resources that need unique names. | string | n/a | yes |
| project\_services | Service APIs enabled by default in new projects. | list | `<list>` | no |
| root\_node | Hierarchy node where projects will be created, 'organizations/org_id' or 'folders/folder_id'. | string | n/a | yes |
| subnet\_secondary\_ranges | Shared VPC subnets secondary range definitions. | map | `<map>` | no |
| subnets | Shared VPC subnet definitions. | list | `<list>` | no |

## Outputs

| Name | Description |
|------|-------------|
| host\_project\_id | VPC host project id. |
| mysql-root-password | Password for the test MySQL db root user. |
| service\_project\_ids | Service project ids. |
| test-instances | Test instance names. |
| vpc\_name | Shared VPC name |
| vpc\_subnets | Shared VPC subnets. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
