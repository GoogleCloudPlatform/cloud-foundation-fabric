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

# locals {
#   interfaces = {
#     1 = module.office-vpc-prod.subnet_ips["${var.region}/prod-default"]
#     2 = module.office-vpc-preprod.subnet_ips["${var.region}/preprod-default"]
#     3 = module.office-vpc-dev.subnet_ips["${var.region}/dev-default"]
#     4 = module.office-vpc-test.subnet_ips["${var.region}/test-default"]
#     5 = module.office-vpc-ss.subnet_ips["${var.region}/ss-default"]
#     6 = module.core-vpc-f5.subnet_ips["${var.region}/f5-default"]
#   }
#   nva_cloud_config = <<-END
#   #cloud-config
#   runcmd:
#   - iptables -P FORWARD ACCEPT
#   - sysctl -w net.ipv4.ip_forward=1
#   %{for k, v in local.interfaces}
#   - ip rule add from ${v} to 35.191.0.0/16 lookup ${k + 110}
#   - ip rule add from ${v} to 130.211.0.0/22 lookup ${k + 110}
#   - ip route add default via ${cidrhost(v, 1)} dev eth${k} proto static onlink table ${k + 110}
#   %{endfor}
#   - ip rule add from ${var.ip_ranges.office-internal} to ${var.ip_ranges.apigee-runtime} lookup 115
#   END
# }
