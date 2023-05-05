# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module "project" {
  source = "../../../modules/project"
  billing_account = (
    var.project_create != null
    ? var.project_create.billing_account_id
    : null
  )
  parent = (
    var.project_create != null
    ? var.project_create.parent
    : null
  )
  project_create = var.project_create != null
  prefix         = var.project_create == null ? null : var.prefix
  name           = var.project_id
  services = [
    "compute.googleapis.com",
    "dns.googleapis.com",
    "managedidentities.googleapis.com"
  ]
}

module "vpc" {
  count      = var.network_config == null ? 1 : 0
  source     = "../../../modules/net-vpc"
  project_id = module.project.project_id
  name       = "${var.prefix}-vpc"
  subnets = [
    {
      ip_cidr_range = var.subnet_ip_cidr_block
      name          = "subnet"
      region        = var.region
    }
  ]
}

resource "google_active_directory_domain" "ad_domain" {
  project             = module.project.project_id
  domain_name         = var.ad_dns_domain_name
  locations           = [var.region]
  authorized_networks = [module.vpc[0].network.id]
  reserved_ip_range   = var.ad_ip_cidr_block
}

module "server" {
  source        = "../../../modules/compute-vm"
  project_id    = module.project.project_id
  zone          = var.zone
  name          = "adfs"
  instance_type = var.instance_type
  network_interfaces = [{
    network    = var.network_config == null ? module.vpc[0].self_link : var.network_config.network
    subnetwork = var.network_config == null ? module.vpc[0].subnet_self_links["${var.region}/subnet"] : var.network_config.subnet
  }]
  metadata = {
    # Enables OpenSSH in the Windows instance
    sysprep-specialize-script-cmd = "googet -noconfirm=true update && googet -noconfirm=true install google-compute-engine-ssh"
    enable-windows-ssh            = "TRUE"
    # Set the default OpenSSH shell to Powershell
    windows-startup-script-ps1 = <<EOT
      New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" `
      -Name DefaultShell `
      -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" `
      -PropertyType String `
      -Force
    EOT
  }
  service_account_create = true
  boot_disk = {
    initialize_params = {
      image = var.image
      type  = var.disk_type
      size  = var.disk_size
    }
  }
  group = {
    named_ports = {
      https = 443
    }
  }
  tags = ["https-server"]
}

module "glb" {
  source     = "../../../modules/net-glb"
  name       = "${var.prefix}-glb"
  project_id = module.project.project_id
  protocol   = "HTTPS"
  backend_service_configs = {
    default = {
      backends        = [{ backend = module.server.group.id }]
      log_sample_rate = 1
      protocol        = "HTTPS"
    }
  }
  health_check_configs = {
    default = {
      https = {
        port_specification = "USE_SERVING_PORT"
      }
    }
  }
  ssl_certificates = {
    managed_configs = {
      adfs-domain = {
        domains = ["${var.adfs_dns_domain_name}"]
      }
    }
  }
}

resource "local_file" "vars_file" {
  content = templatefile("${path.module}/templates/vars.yaml.tpl", {
    project_id           = var.project_id
    ad_dns_domain_name   = var.ad_dns_domain_name
    adfs_dns_domain_name = var.adfs_dns_domain_name
  })
  filename        = "${path.module}/ansible/vars/vars.yaml"
  file_permission = "0666"
}

resource "local_file" "gssh_file" {
  content = templatefile("${path.module}/templates/gssh.sh.tpl", {
    zone       = var.zone
    project_id = var.project_id
  })
  filename        = "${path.module}/ansible/gssh.sh"
  file_permission = "0777"
}
