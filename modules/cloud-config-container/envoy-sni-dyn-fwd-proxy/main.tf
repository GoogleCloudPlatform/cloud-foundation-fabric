/**
 * Copyright 2022 Google LLC
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

module "cos-envoy" {
  source          = "../cos-generic-metadata"
  container_image = var.envoy_image
  container_name  = "envoy"
  container_args  = "-c /etc/envoy/envoy.yaml --log-level info --allow-unknown-static-fields"
  container_volumes = [
    { host = "/etc/envoy/", container = "/etc/envoy/" }
  ]
  docker_args = "--network host --pid host"
  files = {
    "/etc/envoy/envoy.yaml" = {
      content     = file("${path.module}/files/envoy.yaml")
      owner       = "root"
      permissions = "0644"
    }
  }
  run_commands = [
    "iptables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 8443",
    "iptables -A INPUT -p tcp --dport 8443 -j ACCEPT",
    "iptables -t mangle -I PREROUTING -p tcp --dport 8443 -j DROP",
    "systemctl daemon-reload",
    "systemctl start envoy",
  ]
  users = [{
    username = "envoy",
    uid      = 1337
  }]
}
