
locals {
  vms = {
    for f in fileset("${var.data_dir}", "**/*.yaml") :
    trimsuffix(f, ".yaml") => yamldecode(file("${var.data_dir}/${f}"))
  }
}

module "vm-disk-options-example" {
  source = "../../../modules/compute-vm"

  for_each               = local.vms
  project_id             = each.value.project_id
  zone                   = each.value.zone
  name                   = each.value.name
  network_interfaces     = each.value.network_interfaces
  attached_disks         = each.value.attached_disks
  service_account_create = each.value.service_account_create
}
