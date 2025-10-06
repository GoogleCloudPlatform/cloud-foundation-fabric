/**
 * Copyright 2025 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

# tfdoc:file:description Test VM instances factory.

# locals {
#   test_instances = {
#     for i in flatten([
#       for vpc, subnets in local.ctx_vpcs.subnets_by_vpc : [
#         for key, subnet in subnets : {
#           vpc        = local.ctx_vpcs.self_links[vpc]
#           project_id = local.ctx_projects.project_ids[replace(local.vpcs[vpc].project_id, "$project_ids:", "")]
#           name       = "${vpc}-${element(split("/", subnet), -1)}-test-vm"
#           subnet     = subnet
#           region     = split("/", key)[0]
#           zone       = "b"
#           type       = "e2-micro"
#         }
#       ]
#     ]) : i.name => i
#   }

#   vm_pairs = {
#     for pair in setproduct(keys(local.test_instances), keys(local.test_instances)) :
#     "${pair[0]}-to-${pair[1]}" => {
#       source_key = pair[0]
#       dest_key   = pair[1]
#     } if pair[0] != pair[1]
#   }

# }

# module "instances" {
#   source        = "../../../modules/compute-vm"
#   for_each      = local.test_instances
#   project_id    = each.value.project_id
#   zone          = "${each.value.region}-${each.value.zone}"
#   name          = each.value.name
#   instance_type = each.value.type
#   network_interfaces = [{
#     network    = each.value.vpc
#     subnetwork = each.value.subnet
#   }]
# }

# resource "google_network_management_connectivity_test" "vm_connectivity" {
#   for_each = local.vm_pairs
#   project  = local.test_instances[each.value.source_key].project_id
#   name     = "test-${each.key}"
#   protocol = "icmp"
#   labels = {
#     "source-vm" = each.value.source_key
#     "dest-vm"   = each.value.dest_key
#   }
#   source {
#     instance = module.instances[each.value.source_key].id
#   }
#   destination {
#     instance = module.instances[each.value.dest_key].id
#   }
# }
