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

module "projects" {
  source               = "../../../../../fast/stages/03-project-factory/dev"
  data_dir             = "./data/projects/"
  defaults_file        = "./data/defaults.yaml"
  prefix               = "test"
  billing_account_id   = "12345-67890A-BCDEF0"
  environment_dns_zone = "dev"
  shared_vpc_self_link = "fake_link"
  vpc_host_project     = "host_project"
}


