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

output "cloud_config" {
  description = "Rendered cloud-config file to be passed as user-data instance metadata."
  value = templatefile("${path.module}/assets/cloud-config.yaml", {
    files = merge(
      {
        "/var/run/nginx/customize.sh" = {
          content     = file("${path.module}/assets/customize.sh")
          owner       = "root"
          permissions = "0744"
        }
        "/etc/nginx/conf.d/default.conf" = {
          content = templatefile(
            "${path.module}/assets/default.conf", { hello = var.hello }
          )
          owner       = "root"
          permissions = "0644"
        }
      }, var.files
    )
    image = var.image
  })
}
