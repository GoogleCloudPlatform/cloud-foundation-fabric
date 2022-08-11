# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

variable "revision_annotations" {
  description = "Configure revision template annotations."
  type        = any
  default     = null
}

variable "vpc_connector_create" {
  description = "Populate this to create a VPC connector. You can then refer to it in the template annotations."
  type        = any
  default     = null
}

module "cloud_run" {
  source     = "../../../../modules/cloud-run"
  project_id = "my-project"
  name       = "hello"
  audit_log_triggers = [
    {
      "service_name" : "cloudresourcemanager.googleapis.com",
      "method_name" : "SetIamPolicy"
    }
  ]
  containers = [{
    image         = "us-docker.pkg.dev/cloudrun/container/hello"
    options       = null
    ports         = null
    resources     = null
    volume_mounts = null
  }]
  iam = {
    "roles/run.invoker" = ["allUsers"]
  }
  pubsub_triggers = [
    "topic1",
    "topic2"
  ]
  revision_name        = "blue"
  revision_annotations = var.revision_annotations
  vpc_connector_create = var.vpc_connector_create
}
