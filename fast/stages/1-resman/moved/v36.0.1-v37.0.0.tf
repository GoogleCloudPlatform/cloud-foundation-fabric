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
  from = module.net-folder-dev[0]
  to   = module.net-folder-envs["dev"]
}

moved {
  from = module.net-folder-prod[0]
  to   = module.net-folder-envs["prod"]
}

moved {
  from = module.sec-folder-dev[0]
  to   = module.sec-folder-envs["dev"]
}

moved {
  from = module.sec-folder-prod[0]
  to   = module.sec-folder-envs["prod"]
}
