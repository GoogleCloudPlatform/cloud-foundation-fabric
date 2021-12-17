# Google Cloud Data Fusion Module

This module allows simple management of ['Google Data Fusion'](https://cloud.google.com/data-fusion) instances. It supports creating Basic or Enterprise, public or private instances.

## Examples

## Auto-managed IP allocation

```hcl
module "datafusion" {
  source          = "./modules/datafusion"
  name            = "my-datafusion"
  region          = "europe-west1"
  project_id      = "my-project"
  network         = "my-network-name"
  # TODO: remove the following line
  firewall_create = false
}
# tftest:modules=1:resources=3
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
|---|---|:---:|:---:|:---:|
| name | Name of the DataFusion instance. | <code>string</code> | ✓ |  |
| network | Name of the network in the project with which the tenant project will be peered for executing pipelines in the form of projects/{project-id}/global/networks/{network} | <code>string</code> | ✓ |  |
| project_id | Project ID. | <code>string</code> | ✓ |  |
| region | DataFusion region. | <code>string</code> | ✓ |  |
| description | DataFuzion instance description. | <code>string</code> |  | <code>&#34;Terraform managed.&#34;</code> |
| enable_stackdriver_logging | Option to enable Stackdriver Logging. | <code>bool</code> |  | <code>false</code> |
| enable_stackdriver_monitoring | Option to enable Stackdriver Monitorig. | <code>bool</code> |  | <code>false</code> |
| firewall_create | Create Network firewall rules to enable SSH. | <code>bool</code> |  | <code>true</code> |
| ip_allocation | Ip allocated for datafusion instance when not using the auto created one and created outside of the module. | <code>string</code> |  | <code>&#34;null&#34;</code> |
| ip_allocation_create | Create Ip range for datafusion instance. | <code>bool</code> |  | <code>true</code> |
| labels | The resource labels for instance to use to annotate any related underlying resources, such as Compute Engine VMs. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| network_peering | Create Network peering between project and DataFusion tenant project. | <code>bool</code> |  | <code>true</code> |
| private_instance | Create private instance. | <code>bool</code> |  | <code>true</code> |
| type | Datafusion Instance type. It can be BASIC or ENTERPRISE (default value). | <code>string</code> |  | <code>&#34;ENTERPRISE&#34;</code> |

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
