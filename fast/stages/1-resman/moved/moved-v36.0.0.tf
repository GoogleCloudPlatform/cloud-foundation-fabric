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

# stage 3 gke

moved {
  from = module.branch-gke-folder[0]
  to   = module.top-level-folder["gke"]
}
moved {
  from = module.branch-gke-dev-folder[0]
  to   = module.stage3-folder["gke-dev"]
}
moved {
  from = module.branch-gke-prod-folder[0]
  to   = module.stage3-folder["gke-prod"]
}
moved {
  from = module.branch-gke-dev-gcs[0]
  to   = module.stage3-bucket["gke-dev"]
}
moved {
  from = module.branch-gke-prod-gcs[0]
  to   = module.stage3-bucket["gke-prod"]
}
moved {
  from = module.branch-gke-dev-sa[0]
  to   = module.stage3-sa-rw["gke-dev"]
}
moved {
  from = module.branch-gke-prod-sa[0]
  to   = module.stage3-sa-rw["gke-prod"]
}
moved {
  from = module.branch-gke-dev-r-sa[0]
  to   = module.stage3-sa-ro["gke-dev"]
}
moved {
  from = module.branch-gke-prod-r-sa[0]
  to   = module.stage3-sa-ro["gke-prod"]
}

# stage 3 gcve

moved {
  from = module.branch-gcve-folder[0]
  to   = module.top-level-folder["gcve"]
}
moved {
  from = module.branch-gcve-dev-folder[0]
  to   = module.stage3-folder["gcve-dev"]
}
moved {
  from = module.branch-gcve-prod-folder[0]
  to   = module.stage3-folder["gcve-prod"]
}
moved {
  from = module.branch-gcve-dev-gcs[0]
  to   = module.stage3-bucket["gcve-dev"]
}
moved {
  from = module.branch-gcve-prod-gcs[0]
  to   = module.stage3-bucket["gcve-prod"]
}
moved {
  from = module.branch-gcve-dev-sa[0]
  to   = module.stage3-sa-rw["gcve-dev"]
}
moved {
  from = module.branch-gcve-prod-sa[0]
  to   = module.stage3-sa-rw["gcve-prod"]
}
moved {
  from = module.branch-gcve-dev-r-sa[0]
  to   = module.stage3-sa-ro["gcve-dev"]
}
moved {
  from = module.branch-gcve-prod-r-sa[0]
  to   = module.stage3-sa-ro["gcve-prod"]
}
