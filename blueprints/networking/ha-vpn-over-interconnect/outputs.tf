/**
 * Copyright 2023 Google LLC
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

output "underlay" {
  description = "Setup for the underlay connection."
  value = {
    a = {
      vlan_attachment            = module.va-a.attachment.self_link
      cloud_router_ip_address    = module.va-a.attachment.cloud_router_ip_address
      cloud_router_asn           = var.underlay_config.gcp_bgp.asn
      customer_router_ip_address = module.va-a.attachment.customer_router_ip_address
      customer_router_asn        = var.underlay_config.attachments.a.onprem_asn
    }
    b = {
      vlan_attachment            = module.va-b.attachment.self_link
      cloud_router_ip_address    = module.va-b.attachment.cloud_router_ip_address
      cloud_router_asn           = var.underlay_config.gcp_bgp.asn
      customer_router_ip_address = module.va-b.attachment.customer_router_ip_address
      customer_router_asn        = var.underlay_config.attachments.b.onprem_asn
    }
  }
}
