/**
 * Copyright 2023 Google LLC
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

locals {
  envgroups = {
    test = [var.hostname]
  }
  environments = {
    apis-test = {
      envgroups = ["test"]
    }
  }
  org_short_name = (length(module.project.project_id) < 16 ?
    module.project.project_id :
  substr(module.project.project_id, 0, 15))
  org_hash = format("%s-%s", local.org_short_name, substr(sha256(module.project.project_id), 0, 7))
  org_env_hashes = {
    for k, v in local.environments :
    k => format("%s-%s-%s", local.org_short_name, length(k) < 16 ? k : substr(k, 0, 15), substr(sha256("${module.project.project_id}:${k}"), 0, 7))
  }
  google_sas = {
    apigee-metrics = [
      "apigee-metrics-sa"
    ]
    apigee-cassandra = [
      "apigee-cassandra-schema-setup-${local.org_hash}-sa",
      "apigee-cassandra-user-setup-${local.org_hash}-sa"
    ]
    apigee-mart = [
      "apigee-mart-${local.org_hash}-sa",
      "apigee-connect-agent-${local.org_hash}-sa"
    ]
    apigee-watcher = [
      "apigee-watcher-${local.org_hash}-sa"
    ]
    apigee-udca = concat([
      "apigee-udca-${local.org_hash}-sa"
      ],
      [for k, v in local.org_env_hashes :
        "apigee-udca-${local.org_env_hashes[k]}-sa"
    ])
    apigee-synchronizer = [
      for k, v in local.org_env_hashes :
      "apigee-synchronizer-${local.org_env_hashes[k]}-sa"
    ]
    apigee-runtime = [for k, v in local.org_env_hashes :
      "apigee-runtime-${local.org_env_hashes[k]}-sa"
    ]
  }
}

module "apigee" {
  source     = "../../../modules/apigee"
  project_id = module.project.project_id
  organization = {
    analytics_region = var.region
    runtime_type     = "HYBRID"
  }
  envgroups    = local.envgroups
  environments = local.environments
}

module "sas" {
  for_each   = local.google_sas
  source     = "../../../modules/iam-service-account"
  project_id = module.project.project_id
  name       = each.key
  # authoritative roles granted *on* the service accounts to other identities
  iam = {
    "roles/iam.workloadIdentityUser" = [for v in each.value : "serviceAccount:${module.project.project_id}.svc.id.goog[apigee/${v}]"]
  }
}

resource "local_file" "deploy_apiproxy_file" {
  content = templatefile("${path.module}/templates/deploy-apiproxy.sh.tpl", {
    org = module.project.project_id
  })
  filename        = "${path.module}/deploy-apiproxy.sh"
  file_permission = "0755"
}
