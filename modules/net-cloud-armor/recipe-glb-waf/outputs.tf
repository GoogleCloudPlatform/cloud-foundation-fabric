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

output "address" {
  description = "Load balancer address."
  value       = module.glb.address[""]
}

output "commands" {
  description = "Commands to exercise the security policies."
  value = {
    app-request  = "curl -si http://${module.glb.address[""]}/"
    app-sqli     = "curl -si 'http://${module.glb.address[""]}/?id=1%20OR%201=1'"
    app-throttle = "for i in $(seq 1 ${var.rate_limit.count + 10}); do curl -s -o /dev/null -w '%%{http_code}\\n' http://${module.glb.address[""]}/; done | sort | uniq -c"
    static       = "curl -si http://${module.glb.address[""]}/static/index.html"
  }
}

output "security_policies" {
  description = "Security policy ids."
  value = {
    edge = module.edge.id
    waf  = module.waf.id
  }
}
