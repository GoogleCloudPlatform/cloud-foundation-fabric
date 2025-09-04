/**
 * Copyright 2025 Google LLC
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

# networking
moved {
  from = module.net-folder[0]
  to   = module.stage2-folder["networking"]
}
moved {
  from = module.net-folder-envs["dev"]
  to   = module.stage2-folder-env["networking-dev"]
}
moved {
  from = module.net-folder-envs["prod"]
  to   = module.stage2-folder-env["networking-prod"]
}
moved {
  from = module.net-bucket[0]
  to   = module.stage2-bucket["networking"]
}
moved {
  from = module.net-sa-ro[0]
  to   = module.stage2-sa-ro["networking"]
}
moved {
  from = module.net-sa-rw[0]
  to   = module.stage2-sa-rw["networking"]
}
# project factory
# resources change prefix and are recreated anyway
moved {
  from = module.pf-bucket[0]
  to   = module.stage2-bucket["project-factory"]
}
moved {
  from = module.pf-sa-ro[0]
  to   = module.stage2-sa-ro["project-factory"]
}
moved {
  from = module.pf-sa-rw[0]
  to   = module.stage2-sa-rw["project-factory"]
}
# security
moved {
  from = module.sec-folder[0]
  to   = module.stage2-folder["security"]
}
moved {
  from = module.sec-folder-envs["dev"]
  to   = module.stage2-folder-env["security-dev"]
}
moved {
  from = module.sec-folder-envs["prod"]
  to   = module.stage2-folder-env["security-prod"]
}
moved {
  from = module.sec-bucket[0]
  to   = module.stage2-bucket["security"]
}
moved {
  from = module.sec-sa-ro[0]
  to   = module.stage2-sa-ro["security"]
}
moved {
  from = module.sec-sa-rw[0]
  to   = module.stage2-sa-rw["security"]
}
