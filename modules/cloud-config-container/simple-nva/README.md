# Google Simple NVA Module

This module allows for the creation of a NVA (Network Virtual Appliance) to be used for experiments and as a stub for future appliances deployment.

This NVA can be used to interconnect up to 8 VPCs.

Please be aware that the NVA is running [COS](https://cloud.google.com/container-optimized-os/docs). 
Container-Optimized OS (COS) is a Linux-based operating system designed for running containers. By default, COS allows outgoing connections and accepts incoming connections only through the SSH service. To see the exact host firewall configuration, run the following command: 

```sh
sudo iptables -L -v 
```
on a VM instance running COS. More information available in the [official](https://cloud.google.com/container-optimized-os/docs/how-to/firewall) documentation.

To configure the host firewall on COS, you can either pass a custom bash script with iptables commands or use the [optional_firewall_open_ports](variables.tf#L90) variable. The *optional_firewall_open_ports* variable is a list of ports to open on the local firewall for both TCP and UDP protocols.

The recommended solution for more fine-grained control is to pass a custom bash script with iptables commands. This will allow you to open specific ports for specific protocols and interfaces on the host firewall. The [optional_firewall_open_ports](variables.tf#L90) variable is a more convenient option, but you can only specify a list of ports to be opened for both TCP and UDP protocols on all the network interfaces with no further filtering capabilities.

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
    initialize_params = {
      image = "projects/cos-cloud/global/images/family/cos-stable"
      type  = "pd-ssd"
      size  = 10
    }
  }
  tags = ["nva", "ssh"]
}
# tftest modules=1 resources=1
```

### Example with advanced routing capabilities

Find below a sample terraform example for bootstrapping a simple NVA powered by [COS](https://cloud.google.com/container-optimized-os/docs) and running [FRRouting](https://frrouting.org/) container. FRR container is managed as a systemd service named frr. For stopping, starting or restarting the container please use the following commands:

```sh
sudo systemctl stop frr
sudo systemctl start frr
sudo systemctl restart frr
```

Being a fork of [Quagga](https://en.wikipedia.org/wiki/Quagga_(software)), FRR offers the same VTY shell named vtysh to deal with all the running daemons. It is possible to  access the vtysh on the container via the following procedure:
1. issue a `sudo docker container ls` to get the container ID
2. execute `docker exec -it ${CONTAINER_ID} vtysh` to get a VTYSH shell running on the container and manage frr software

In order to check FRR running configuration you can issue the `show running-config` from vtysh. Please always refer to the official documentation for more information how to deal with vtysh and useful commands.

Please find below a sample frr.conf file based on the documentation available [here](https://docs.frrouting.org/en/latest/basic.html) for hosting a BGP service with ASN 65001 on FRR container establishing a BGP session with a remote neighbor with IP address 10.128.0.2 and ASN 65002. 
In order to check BGP status for the bootstrapped NVA you can issue 'show bgp summary' from vtysh. 

When configuring FRR, this module automatically configures the local firewall to accept inbound connections for well known protocols enabled in the daemons_enabled parameter of the [frr_config](variables.tf#L39) variable. For example, when configuring BGP, the local firewall will be automatically configured to accept connections on port 179.

```
# tftest-file id=frr_conf path=./frr.conf
# Example frr.conmf file

log syslog informational
no ipv6 forwarding
router bgp 65001
 neighbor 10.128.0.2 remote-as 65002
line vty
```

Following code assumes a file in the same folder named frr.conf exists. 

```hcl
locals {
  network_interfaces = [
    {
      addresses           = null
      name                = "dev"
      nat                 = false
      network             = "dev_vpc_self_link"
      routes              = ["10.128.0.0/9"]
      subnetwork          = "dev_vpc_nva_subnet_self_link"
      enable_masquerading = true
      non_masq_cidrs      = ["10.0.0.0/8"]
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
  frr_config           = { config_file = "./frr.conf", daemons_enabled = ["bgpd"] }
  optional_run_cmds    = ["ls -l"]
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
# tftest modules=1 resources=1 files=frr_conf
```
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [network_interfaces](variables.tf#L75) | Network interfaces configuration. | <code title="list&#40;object&#40;&#123;&#10;  routes              &#61; optional&#40;list&#40;string&#41;&#41;&#10;  enable_masquerading &#61; optional&#40;bool, false&#41;&#10;  non_masq_cidrs      &#61; optional&#40;list&#40;string&#41;&#41;&#10;&#125;&#41;&#41;">list&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> | ✓ |  |
| [cloud_config](variables.tf#L17) | Cloud config template path. If null default will be used. | <code>string</code> |  | <code>null</code> |
| [enable_health_checks](variables.tf#L23) | Configures routing to enable responses to health check probes. | <code>bool</code> |  | <code>false</code> |
| [files](variables.tf#L29) | Map of extra files to create on the instance, path as key. Owner and permissions will use defaults if null. | <code title="map&#40;object&#40;&#123;&#10;  content     &#61; string&#10;  owner       &#61; string&#10;  permissions &#61; string&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [frr_config](variables.tf#L39) | FRR configuration for container running on the NVA. | <code title="object&#40;&#123;&#10;  config_file     &#61; string&#10;  daemons_enabled &#61; optional&#40;list&#40;string&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [optional_firewall_open_ports](variables.tf#L84) | Optional Ports to be opened on the local firewall. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [optional_run_cmds](variables.tf#L90) | Optional Cloud Init run commands to execute. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [cloud_config](outputs.tf#L17) | Rendered cloud-config file to be passed as user-data instance metadata. |  |

<!-- END TFDOC -->
