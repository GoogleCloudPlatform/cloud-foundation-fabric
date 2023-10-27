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

# tfdoc:file:description Network tester image.

# Service A container image. It is a network tester with a GUI.
# Build the image to run in service A and push it to Artifact Registry.
module "docker_artifact_registry" {
  source     = "../../../modules/artifact-registry"
  project_id = module.project_main.project_id
  location   = var.region
  name       = local.repo
}

# The source code is within ./code folder.
resource "null_resource" "image" {
  provisioner "local-exec" {
    command     = <<-EOT
      gcloud builds submit --region=${var.region} \
      --project=${var.prj_main_id} \
      --tag=${local.svc_a_image}
    EOT
    working_dir = "./code"
  }

  # Wait for the Artifact Registry repo to exist
  depends_on = [module.docker_artifact_registry]
}
