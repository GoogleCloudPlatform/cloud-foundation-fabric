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

resource "local_file" "target_endpoint_file" {
  content = templatefile("${path.module}/templates/targets/default.xml.tpl", {
    ip_address = module.apigee.endpoint_attachment_hosts["backend"]
  })
  filename        = "${path.module}/bundle/apiproxy/targets/default.xml"
  file_permission = "0777"
}

data "archive_file" "bundle" {
  type        = "zip"
  source_dir  = "${path.module}/bundle"
  output_path = "${path.module}/bundle.zip"
  depends_on = [
    local_file.target_endpoint_file
  ]
}

resource "local_file" "deploy_apiproxy_file" {
  content = templatefile("${path.module}/templates/deploy-apiproxy.sh.tpl", {
    organization = module.apigee.org_name
    environment  = local.environment
  })
  filename        = "${path.module}/deploy-apiproxy.sh"
  file_permission = "0777"
}
