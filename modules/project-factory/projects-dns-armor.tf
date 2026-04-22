/**
 * Copyright 2026 Google LLC
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

resource "google_network_security_dns_threat_detector" "dns_threat_detector" {
  provider = google-beta
  for_each = {
    for k, v in local.projects_input : k => v
    if try(v.dns_threat_detector.enabled, false)
  }
  project = module.projects[each.key].project_id
  name = (
    try(each.value.dns_threat_detector.name, null) != null
    ? each.value.dns_threat_detector.name
    : (
      each.value.prefix == null
      ? each.value.name
      : "${each.value.prefix}-${each.value.name}"
    )
  )
  excluded_networks = [
    for s in try(each.value.dns_threat_detector.excluded_networks, []) :
    lookup(local.ctx.networks, s, s)
  ]
  threat_detector_provider = try(each.value.dns_threat_detector.threat_detector_provider, null)
  labels                   = try(each.value.dns_threat_detector.labels, {})
  location                 = try(each.value.dns_threat_detector.location, null)
}
