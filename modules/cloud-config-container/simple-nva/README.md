# Google Simple NVA Module

This module allows for the creation of a NVA (Network Virtual Appliance) to be used for experiments and as a stub for future appliances deployment.

This NVA can be used to interconnect up to 8 VPCs.

## Examples

### Simple example

```hcl
locals {
  network_interfaces = [
    {
      addresses  = null
      name       = "dev"
      nat        = false
      network    = "dev_vpc_self_link"
      routes     = ["10.128.0.0/9"]
      subnetwork = "dev_vpc_nva_subnet_self_link"
    },
    {
      addresses  = null
      name       = "prod"
      nat        = false
      network    = "prod_vpc_self_link"
      routes     = ["10.0.0.0/9"]
      subnetwork = "prod_vpc_nva_subnet_self_link"
    }
  ]
}

module "cos-nva" {
  source               = "./fabric/modules/cloud-config-container/simple-nva"
  enable_health_checks = true
  network_interfaces   = local.network_interfaces
  # files = {
  #   "/var/lib/cloud/scripts/per-boot/firewall-rules.sh" = {
  #     content     = file("./your_path/to/firewall-rules.sh")
  #     owner       = "root"
  #     permissions = 0700
  #   }
  # }
}

module "vm" {
  source             = "./fabric/modules/compute-vm"
  project_id         = "my-project"
  zone               = "europe-west8-b"
  name               = "cos-nva"
  network_interfaces = local.network_interfaces
  metadata = {
    user-data              = module.cos-nva.cloud_config
    google-logging-enabled = true
  }
  boot_disk = {
    image = "projects/cos-cloud/global/images/family/cos-stable"
    type  = "pd-ssd"
    size  = 10
  }
  tags = ["nva", "ssh"]
}
# tftest modules=1 resources=1
```
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [network_interfaces](variables.tf#L39) | Network interfaces configuration. | <code title="list&#40;object&#40;&#123;&#10;  routes &#61; optional&#40;list&#40;string&#41;&#41;&#10;&#125;&#41;&#41;">list&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> | ✓ |  |
| [cloud_config](variables.tf#L17) | Cloud config template path. If null default will be used. | <code>string</code> |  | <code>null</code> |
| [enable_health_checks](variables.tf#L23) | Configures routing to enable responses to health check probes. | <code>bool</code> |  | <code>false</code> |
| [files](variables.tf#L29) | Map of extra files to create on the instance, path as key. Owner and permissions will use defaults if null. | <code title="map&#40;object&#40;&#123;&#10;  content     &#61; string&#10;  owner       &#61; string&#10;  permissions &#61; string&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [cloud_config](outputs.tf#L17) | Rendered cloud-config file to be passed as user-data instance metadata. |  |

<!-- END TFDOC -->
