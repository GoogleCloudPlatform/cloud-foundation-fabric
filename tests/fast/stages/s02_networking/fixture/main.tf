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

module "stage" {
  source             = "../../../../../fast/stages/02-networking"
  billing_account_id = "000000-111111-222222"
  organization = {
    domain      = "gcp-pso-italy.net"
    id          = 856933387836
    customer_id = "C01lmug8b"
  }
  prefix = "fast"
  project_factory_sa = {
    dev  = "foo@iam"
    prod = "bar@iam"
  }
}
