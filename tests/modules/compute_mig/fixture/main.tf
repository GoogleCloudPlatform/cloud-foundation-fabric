/**
 * Copyright 2021 Google LLC
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

module "test" {
  source      = "../../../../modules/compute-mig"
  project_id  = "my-project"
  location    = "europe-west1"
  name        = "test-mig"
  target_size = 2
  default_version = {
    instance_template = "foo-template"
    name              = "foo"
  }
  autoscaler_config   = var.autoscaler_config
  health_check_config = var.health_check_config
  named_ports         = var.named_ports
  regional            = var.regional
  update_policy       = var.update_policy
  versions            = var.versions
}
