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

module "cloud_run" {
  source        = "../../../../modules/cloud-run"
  project_id    = "my-project"
  name          = "hello"
  revision_name = "blue"
  containers = [{
    image         = "us-docker.pkg.dev/cloudrun/container/hello"
    options       = null
    ports         = null
    resources     = null
    volume_mounts = null
  }]
  audit_log_triggers = [
    {
      "service_name" : "cloudresourcemanager.googleapis.com",
      "method_name" : "SetIamPolicy"
    }
  ]
  pubsub_triggers = [
    "topic1",
    "topic2"
  ]
  iam = {
    "roles/run.invoker" = ["allUsers"]
  }
}
