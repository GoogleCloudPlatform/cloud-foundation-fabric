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
  from = module.branch-network-prod-folder
  to   = module.net-folder-prod[0]
}
moved {
  from = module.branch-network-dev-folder
  to   = module.net-folder-dev[0]
}
moved {
  from = module.branch-network-sa
  to   = module.net-sa-rw[0]
}
moved {
  from = module.branch-network-r-sa
  to   = module.net-sa-ro[0]
}
moved {
  from = module.branch-network-gcs
  to   = module.net-bucket[0]
}
moved {
  from = module.branch-network-sa-cicd["0"]
  to   = module.cicd-sa-rw["networking"]
}
moved {
  from = module.branch-network-r-sa-cicd["0"]
  to   = module.cicd-sa-ro["networking"]
}

# stage 2 security
moved {
  from = module.branch-security-folder
  to   = module.sec-folder[0]
}
moved {
  from = module.branch-security-prod-folder
  to   = module.sec-folder-prod[0]
}
moved {
  from = module.branch-security-dev-folder
  to   = module.sec-folder-dev[0]
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
  from = module.branch-security-gcs
  to   = module.sec-bucket[0]
}
moved {
  from = module.branch-security-sa-cicd["0"]
  to   = module.cicd-sa-rw["security"]
}
moved {
  from = module.branch-security-r-sa-cicd["0"]
  to   = module.cicd-sa-ro["security"]
}

# stage 2 project factory
# moved {
#   from = module.branch-pf-sa[0]
#   to   = module.branch-pf-sa
# }
moved {
  from = module.branch-pf-sa
  to   = module.pf-sa-rw[0]
}
# moved {
#   from = module.branch-pf-r-sa[0]
#   to   = module.pf-sa-ro
# }
moved {
  from = module.branch-pf-r-sa
  to   = module.pf-sa-ro[0]
}

# stage 3 gcve

moved {
  from = module.branch-gcve-folder
  to   = module.stage3-folder["gcve"]
}
moved {
  from = module.branch-gcve-prod-folder
  to   = module.stage3-folder-prod["gcve"]
}
moved {
  from = module.branch-gcve-dev-folder
  to   = module.stage3-folder-dev["gcve"]
}
moved {
  from = module.branch-gcve-prod-sa
  to   = module.stage3-sa-prod-rw["gcve"]
}
moved {
  from = module.branch-gcve-prod-r-sa
  to   = module.stage3-sa-prod-ro["gcve"]
}
moved {
  from = module.branch-gcve-dev-sa
  to   = module.stage3-sa-dev-rw["gcve"]
}
moved {
  from = module.branch-gcve-dev-r-sa
  to   = module.stage3-sa-dev-ro["gcve"]
}
moved {
  from = module.branch-gcve-prod-gcs
  to   = module.stage3-bucket-prod["gcve"]
}
moved {
  from = module.branch-gcve-dev-gcs
  to   = module.stage3-bucket-dev["gcve"]
}

# stage 3 gke

moved {
  from = module.branch-gke-folder
  to   = module.stage3-folder["gke"]
}
moved {
  from = module.branch-gke-prod-folder
  to   = module.stage3-folder-prod["gke"]
}
moved {
  from = module.branch-gke-dev-folder
  to   = module.stage3-folder-dev["gke"]
}
moved {
  from = module.branch-gke-prod-sa
  to   = module.stage3-sa-prod-rw["gke"]
}
moved {
  from = module.branch-gke-prod-r-sa
  to   = module.stage3-sa-prod-ro["gke"]
}
moved {
  from = module.branch-gke-dev-sa
  to   = module.stage3-sa-dev-rw["gke"]
}
moved {
  from = module.branch-gke-dev-r-sa
  to   = module.stage3-sa-dev-ro["gke"]
}
moved {
  from = module.branch-gke-prod-gcs
  to   = module.stage3-bucket-prod["gke"]
}
moved {
  from = module.branch-gke-dev-gcs
  to   = module.stage3-bucket-dev["gke"]
}

# stage 3 data platform

moved {
  from = module.branch-dp-folder
  to   = module.stage3-folder["dp"]
}
moved {
  from = module.branch-dp-prod-folder
  to   = module.stage3-folder-prod["dp"]
}
moved {
  from = module.branch-dp-dev-folder
  to   = module.stage3-folder-dev["dp"]
}
moved {
  from = module.branch-dp-prod-sa
  to   = module.stage3-sa-prod-rw["dp"]
}
moved {
  from = module.branch-dp-prod-r-sa
  to   = module.stage3-sa-prod-ro["dp"]
}
moved {
  from = module.branch-dp-dev-sa
  to   = module.stage3-sa-dev-rw["dp"]
}
moved {
  from = module.branch-dp-dev-r-sa
  to   = module.stage3-sa-dev-ro["dp"]
}
moved {
  from = module.branch-dp-prod-gcs
  to   = module.stage3-bucket-prod["dp"]
}
moved {
  from = module.branch-dp-dev-gcs
  to   = module.stage3-bucket-dev["dp"]
}

# stage 3 nsec

# moved {
#   from = module.branch-nsec-sa
#   to   = module.stage3-sa-prod-rw["nsec"]
# }
moved {
  from = module.branch-nsec-sa[0]
  to   = module.stage3-sa-prod-rw["nsec"]
}
# moved {
#   from = module.branch-nsec-r-sa
#   to   = module.stage3-sa-prod-ro["nsec"]
# }
moved {
  from = module.branch-nsec-r-sa[0]
  to   = module.stage3-sa-prod-ro["nsec"]
}
# moved {
#   from = module.branch-nsec-gcs
#   to   = module.stage3-bucket-prod["nsec"]
# }
moved {
  from = module.branch-nsec-gcs[0]
  to   = module.stage3-bucket-prod["nsec"]
}

# stage 3 sandbox

moved {
  from = module.branch-sandbox-folder
  to   = module.stage3-folder["sbx"]
}
moved {
  from = module.branch-sandbox-sa
  to   = module.stage3-sa-prod-rw["sbx"]
}
moved {
  from = module.branch-sandbox-gcs
  to   = module.stage3-bucket-prod["sbx"]
}
