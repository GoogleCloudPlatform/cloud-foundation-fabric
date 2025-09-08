/**
 * Copyright 2024 Google LLC
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

moved {
  from = module.dev-sec-kms["europe"]
  to   = module.kms["dev-europe"]
}
moved {
  from = module.dev-sec-kms["europe-west1"]
  to   = module.kms["dev-europe-west1"]
}
moved {
  from = module.dev-sec-kms["europe-west3"]
  to   = module.kms["dev-europe-west3"]
}
moved {
  from = module.dev-sec-kms["global"]
  to   = module.kms["dev-global"]
}
moved {
  from = module.dev-sec-project
  to   = module.project["dev"]

}

moved {
  from = module.prod-sec-kms["europe"]
  to   = module.kms["prod-europe"]
}
moved {
  from = module.prod-sec-kms["europe-west1"]
  to   = module.kms["prod-europe-west1"]
}
moved {
  from = module.prod-sec-kms["europe-west3"]
  to   = module.kms["prod-europe-west3"]
}
moved {
  from = module.prod-sec-kms["global"]
  to   = module.kms["prod-global"]
}
moved {
  from = module.prod-sec-project
  to   = module.project["prod"]
}
