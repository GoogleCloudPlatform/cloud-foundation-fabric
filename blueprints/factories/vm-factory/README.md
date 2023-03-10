# Google Cloud VM Factory

This module allows creation and management of compute VM's by defining them in well formatted `yaml` files.

Yaml abstraction for VM creation can simplify users onboarding compared to HCL.

This factory is based on the [compute-vm module](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/tree/master/modules/compute-vm)

You can create as many files as you like, the code will loop through it and create the required variables in order to execute everything accordingly.

## Example

### Directory structure

```
.
├── data
│   ├── vm1.yaml
│   ├── vm2.yaml
├── main.tf
└── variables.tf
```

### VM configuration

```yaml
# ./data/vm1.yaml
# One file per vm

project_id: vm-factory-testing
name: "instance-01"
region: "us-central1"
zone: "us-central1-a"
service_account_create: true
network_interfaces: 
    - nat: false
      network: "projects/vm-factory-testing/global/networks/default"
      subnetwork: "projects/vm-factory-testing/regions/us-central1/subnetworks/default"
      addresses: null

attached_disks:
      - name: "data1"
        size:  "10"
        source_type: null
        options: 
          auto_delete: false
          mode: "READ_WRITE"
          replica_zone: null
          type: "pd-ssd"
```

```yaml
# ./data/vm2.yaml
# One file per vm

project_id: vm-factory-testing
name: "instance-02"
region: "us-central1"
zone: "us-central1-a"
service_account_create: false
network_interfaces: 
    - nat: false
      network: "projects/vm-factory-testing/global/networks/default"
      subnetwork: "projects/vm-factory-testing/regions/us-central1/subnetworks/default"
      addresses: null

attached_disks:
      - name: "data1"
        size:  "10"
        source_type: null
        options: 
          auto_delete: false
          mode: "READ_WRITE"
          replica_zone: null
          type: "pd-ssd"
      - name: "data2"
        size:  "10"
        source_type: "image"
        source: "image-1"
        options: 
          auto_delete: false
          mode: "READ_WRITE"
          replica_zone: null
          type: "pd-ssd"
```

### Terraform code

```hcl
locals {
  vms = {
    for f in fileset("${var.data_dir}", "**/*.yaml") :
    trimsuffix(f, ".yaml") => yamldecode(file("${var.data_dir}/${f}"))
  }
}

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