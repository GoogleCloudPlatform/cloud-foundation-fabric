# Google Cloud VM Factory

This module allows creation and management of compute VM's by defining them in well formatted `yaml` files.

Yaml abstraction for VM creation can simplify users onboarding compared to HCL.

This factory is based on the [compute-vm module](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/tree/master/modules/compute-vm)

You can create as many files as you like, the code will loop through it and create the required variables in order to execute everything accordingly.

## Example

### Terraform code

```hcl
module "vm-disk-factory-example" {
  source = "../../../modules/compute-vm"

  for_each               = local.vms
  project_id             = each.value.project_id
  zone                   = each.value.zone
  name                   = each.value.name
  network_interfaces     = each.value.network_interfaces
  attached_disks         = each.value.attached_disks
  service_account_create = teach.value.create_service_account
}
# tftest skip
```

<!-- BEGIN_TF_DOCS -->

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_vm-disk-options-example"></a> [vm-disk-options-example](#module\_vm-disk-options-example) | ../../../modules/compute-vm | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_data_dir"></a> [data\_dir](#input\_data\_dir) | Relative path for the folder storing configuration data. | `string` | `"data/vms/"` | no |
| <a name="input_network_interfaces"></a> [network\_interfaces](#input\_network\_interfaces) | Network interfaces configuration. Use self links for Shared VPC, set addresses to null if not needed. | <pre>list(object({<br>    nat        = optional(bool, false)<br>    network    = string<br>    subnetwork = string<br>    addresses = optional(object({<br>      internal = string<br>      external = string<br>    }), null)<br>    alias_ips = optional(map(string), {})<br>    nic_type  = optional(string)<br>  }))</pre> | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Project id, references existing project if `project_create` is null. | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->