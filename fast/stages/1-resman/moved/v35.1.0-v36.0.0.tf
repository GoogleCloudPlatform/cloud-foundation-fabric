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

# stage 2 networking

moved {
  from = module.branch-network-folder
  to   = module.net-folder[0]
}
moved {
  from = module.branch-network-dev-folder
  to   = module.net-folder-dev[0]
}
moved {
  from = module.branch-network-prod-folder
  to   = module.net-folder-prod[0]
}
moved {
  from = module.branch-network-gcs
  to   = module.net-bucket[0]
}
moved {
  from = module.branch-network-sa
  to   = module.net-sa-ro[0]
}
moved {
  from = module.branch-network-r-sa
  to   = module.net-sa-rw[0]
}

# stage 2 network security

moved {
  from = module.branch-nsec-gcs[0]
  to   = module.nsec-bucket[0]
}
moved {
  from = module.branch-nsec-sa[0]
  to   = module.nsec-sa-rw[0]
}
moved {
  from = module.branch-nsec-r-sa[0]
  to   = module.nsec-sa-ro[0]
}
moved {
  from = module.branch-networking-sa-cicd["0"]
  to   = module.cicd-sa-rw["networking"]
}
moved {
  from = module.branch-networking-r-sa-cicd["0"]
  to   = module.cicd-sa-ro["networking"]
}

# stage 2 project factory

moved {
  from = module.branch-pf-gcs
  to   = module.pf-bucket[0]
}
moved {
  from = module.branch-pf-sa
  to   = module.pf-sa-rw[0]
}
moved {
  from = module.branch-pf-r-sa
  to   = module.pf-sa-ro[0]
}
moved {
  from = module.branch-pf-sa-cicd
  to   = module.cicd-sa-rw["project-factory"]
}
moved {
  from = module.branch-pf-r-sa-cicd
  to   = module.cicd-sa-ro["project-factory"]
}

# stage 2 security

moved {
  from = module.branch-security-folder
  to   = module.sec-folder[0]
}
moved {
  from = module.branch-security-gcs
  to   = module.sec-bucket[0]
}
moved {
  from = module.branch-security-sa
  to   = module.sec-sa-rw[0]
}
moved {
  from = module.branch-security-r-sa
  to   = module.sec-sa-ro[0]
}
moved {
  from = module.branch-security-sa-cicd["0"]
  to   = module.cicd-sa-rw["security"]
}
moved {
  from = module.branch-security-r-sa-cicd["0"]
  to   = module.cicd-sa-ro["security"]
}

# project factory dev

moved {
  from = module.branch-pf-dev-gcs
  to   = module.stage3-bucket["project-factory-dev"]
}
moved {
  from = module.branch-pf-dev-sa
  to   = module.stage3-sa-rw["project-factory-dev"]
}
moved {
  from = module.branch-pf-dev-r-sa
  to   = module.stage3-sa-ro["project-factory-dev"]
}

# project factory prod

moved {
  from = module.branch-pf-prod-gcs
  to   = module.stage3-bucket["project-factory-prod"]
}
moved {
  from = module.branch-pf-prod-sa
  to   = module.stage3-sa-rw["project-factory-prod"]
}
moved {
  from = module.branch-pf-prod-r-sa
  to   = module.stage3-sa-ro["project-factory-prod"]
}

# sandbox

moved {
  from = module.branch-sandbox-folder[0]
  to   = module.top-level-folder["sandbox"]
}
moved {
  from = module.branch-sandbox-gcs[0]
  to   = module.top-level-bucket["sandbox"]
}
moved {
  from = module.branch-sandbox-sa[0]
  to   = module.top-level-sa["sandbox"]
}

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
