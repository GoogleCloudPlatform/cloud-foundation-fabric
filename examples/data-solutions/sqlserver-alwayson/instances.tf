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

# tfdoc:file:description Creates SQL Server instances and witness.
locals {
  secret_parts = split("/", module.secret-manager.secrets[local.ad_user_password_secret].id)
  user_name    = format("%ssqlserver", local.prefix)
  template_vars = {
    prefix                    = var.prefix
    ad_domain                 = var.ad_domain_fqdn
    ad_netbios                = var.ad_domain_netbios
    managed_ad_dn             = var.managed_ad_dn
    managed_ad_dn_path        = var.managed_ad_dn != "" ? format("-Path \"%s\"", var.managed_ad_dn) : ""
    health_check_port         = var.health_check_port
    sql_admin_password_secret = local.secret_parts[length(local.secret_parts) - 1]
    cluster_ip                = module.ip-addresses.internal_addresses[format("%scluster", local.prefix)].address
    loadbalancer_ips          = jsonencode({ for aog in var.always_on_groups : aog => module.ip-addresses.internal_addresses[format("%slb-%s", local.prefix, aog)].address })
    sql_cluster_name          = local.cluster_netbios_name
    sql_cluster_full          = local.cluster_full_name
    node_netbios_1            = local.node_netbios_names[0]
    node_netbios_2            = local.node_netbios_names[1]
    witness_netbios           = local.witness_netbios_name
    always_on_groups          = join(",", var.always_on_groups)
    sql_user_name             = length(local.user_name) > 20 ? substr(local.user_name, 0, 20) : local.user_name
  }
}

# Common Powershell functions
data "template_file" "functions-script" {
  template = file(format("%s/scripts/functions.ps1", path.module))
  vars     = local.template_vars
}

# Specialization scripts
data "template_file" "specialize-node-script" {
  template = file(format("%s/scripts/specialize-node.ps1", path.module))
  vars     = merge(local.template_vars, { functions = data.template_file.functions-script.rendered })
}

data "template_file" "specialize-witness-script" {
  template = file(format("%s/scripts/specialize-witness.ps1", path.module))
  vars     = merge(local.template_vars, { functions = data.template_file.functions-script.rendered })
}

# Startup scripts
data "template_file" "startup-node-script" {
  template = file(format("%s/scripts/windows-startup-node.ps1", path.module))
  vars     = merge(local.template_vars, { functions = data.template_file.functions-script.rendered })
}

data "template_file" "startup-witness-script" {
  template = file(format("%s/scripts/windows-startup-witness.ps1", path.module))
  vars     = merge(local.template_vars, { functions = data.template_file.functions-script.rendered })
}

# Nodes
module "nodes" {
  source   = "../../../modules/compute-vm"
  for_each = toset(local.node_netbios_names)

  project_id = var.project_id
  zone       = local.node_zones[each.value]
  name       = each.value

  instance_type = var.node_instance_type

  network_interfaces = [{
    network    = local.network
    subnetwork = local.subnetwork
    nat        = false
    addresses = {
      internal = module.ip-addresses.internal_addresses[each.value].address
      external = null
    }
  }]

  boot_disk = {
    image = var.node_image
    type  = "pd-ssd"
    size  = var.boot_disk_size
  }

  attached_disks = [{
    name        = format("%s-datadisk", each.value)
    size        = var.data_disk_size
    source_type = null
    source      = null
    options     = null
  }]

  service_account        = module.compute-service-account.email
  service_account_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  metadata = {
    enable-wsfc                   = "true"
    sysprep-specialize-script-ps1 = data.template_file.specialize-node-script.rendered
    windows-startup-script-ps1    = data.template_file.startup-node-script.rendered
  }

  group = {
    named_ports = {
    }
  }

  service_account_create = false
  create_template        = false
}

# Witness
module "witness" {
  source   = "../../../modules/compute-vm"
  for_each = toset([local.witness_netbios_name])

  project_id = var.project_id
  zone       = local.node_zones[each.value]
  name       = each.value

  instance_type = var.witness_instance_type

  network_interfaces = [{
    network    = local.network
    subnetwork = local.subnetwork
    nat        = false
    addresses = {
      internal = module.ip-addresses.internal_addresses[each.value].address
      external = null
    }
  }]

  boot_disk = {
    image = var.witness_image
    type  = "pd-ssd"
    size  = var.boot_disk_size
  }

  service_account        = module.witness-service-account.email
  service_account_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  metadata = {
    sysprep-specialize-script-ps1 = data.template_file.specialize-witness-script.rendered
    windows-startup-script-ps1    = data.template_file.startup-witness-script.rendered
  }

  service_account_create = false
  create_template        = false
}
