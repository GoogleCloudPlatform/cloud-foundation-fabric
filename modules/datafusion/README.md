# Google Cloud DNS Module

This module allows simple management of ['Google Data Fusion'](https://cloud.google.com/data-fusion) instances. It supports creating Basi or Enterprise, public or private instances. 

## Example

```hcl
module "datafusion" {
  source     = "./modules/datafusion"
  name       = "my-datafusion"
  region     = "europe-west1"
  project_id = "my-project"
  network    = "my-network-name"
}
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| name | Name of the DataFusion instance. | <code title="">string</code> | ✓ |  |
| network | Name of the network in the project with which the tenant project will be peered for executing pipelines in the form of projects/{project-id}/global/networks/{network} | <code title="">string</code> | ✓ |  |
| project_id | Project ID. | <code title="">string</code> | ✓ |  |
| region | DataFusion region. | <code title="">string</code> | ✓ |  |
| *description* | DataFuzion instance description. | <code title="">string</code> |  | <code title="">Terraform managed.</code> |
| *enable_stackdriver_logging* | Option to enable Stackdriver Logging. | <code title="">bool</code> |  | <code title="">false</code> |
| *enable_stackdriver_monitoring* | Option to enable Stackdriver Monitorig. | <code title="">bool</code> |  | <code title="">false</code> |
| *labels* | The resource labels for instance to use to annotate any related underlying resources, such as Compute Engine VMs. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">{}</code> |
| *network_firewall_rules* | Create Network firewall rules to enable SSH. | <code title="">bool</code> |  | <code title="">true</code> |
| *network_peering* | Create Network peering between project and DataFusion tenant project. | <code title="">bool</code> |  | <code title="">true</code> |
| *private_instance* | Create private instance. | <code title="">bool</code> |  | <code title="">true</code> |
| *shared_network_config* | Shared Network Configuration parameters. | <code title="map&#40;object&#40;&#123;&#10;project_number &#61; number&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |
| *type* | Datafusion Instance type. It can be BASIC or ENTERPRISE (default value). | <code title="">string</code> |  | <code title="">ENTERPRISE</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| id | DataFusion instance ID. |  |
| ip_allocation | IP range reserved for Data Fusion instance in case of a private instance. |  |
| service_account | DataFusion Service Account. |  |
| service_endpoint | DataFusion Service Endpoint. |  |
| version | DataFusion version. |  |
<!-- END TFDOC -->
