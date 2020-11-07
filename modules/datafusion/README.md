# Google Cloud Data Fusion Module

This module allows simple management of ['Google Data Fusion'](https://cloud.google.com/data-fusion) instances. It supports creating Basic or Enterprise, public or private instances. 

## Examples

## Auto-managed IP allocation

```hcl
module "datafusion" {
  source     = "./modules/datafusion"
  name       = "my-datafusion"
  region     = "europe-west1"
  project_id = "my-project"
  network    = "my-network-name"
}
# tftest:modules=1:resources=4
```

### Externally managed IP allocation

```hcl
module "datafusion" {
  source               = "./modules/datafusion"
  name                 = "my-datafusion"
  region               = "europe-west1"
  project_id           = "my-project"
  network              = "my-network-name"
  ip_allocation_create = false
  ip_allocation        = "10.0.0.0/22"
}
# tftest:modules=1:resources=3
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
| *firewall_create* | Create Network firewall rules to enable SSH. | <code title="">bool</code> |  | <code title="">true</code> |
| *ip_allocation* | Ip allocated for datafusion instance when not using the auto created one and created outside of the module. | <code title="">string</code> |  | <code title="">null</code> |
| *ip_allocation_create* | Create Ip range for datafusion instance. | <code title="">bool</code> |  | <code title="">true</code> |
| *labels* | The resource labels for instance to use to annotate any related underlying resources, such as Compute Engine VMs. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">{}</code> |
| *network_peering* | Create Network peering between project and DataFusion tenant project. | <code title="">bool</code> |  | <code title="">true</code> |
| *private_instance* | Create private instance. | <code title="">bool</code> |  | <code title="">true</code> |
| *type* | Datafusion Instance type. It can be BASIC or ENTERPRISE (default value). | <code title="">string</code> |  | <code title="">ENTERPRISE</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| id | DataFusion instance ID. |  |
| ip_allocation | IP range reserved for Data Fusion instance in case of a private instance. |  |
| resource | DataFusion resource. |  |
| service_account | DataFusion Service Account. |  |
| service_endpoint | DataFusion Service Endpoint. |  |
| version | DataFusion version. |  |
<!-- END TFDOC -->
