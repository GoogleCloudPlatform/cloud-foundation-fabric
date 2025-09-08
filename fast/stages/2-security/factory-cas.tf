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

locals {
  _ca_pools_path = try(
    pathexpand(var.factories_config.certificate_authorities), null
  )
  _ca_pools_files = try(
    fileset(local._ca_pools_path, "**/*.yaml"),
    []
  )
  _ca_pools = {
    for f in local._ca_pools_files : trimsuffix(basename(f), ".yaml") => yamldecode(file(
      "${coalesce(local._ca_pools_path, "-")}/${f}"
    ))
  }
  ca_pools = {
    for k, v in local._ca_pools : k => {
      location              = v.location
      project_id            = v.project_id
      iam                   = lookup(v, "iam", {})
      iam_bindings          = lookup(v, "iam_bindings", {})
      iam_bindings_additive = lookup(v, "iam_bindings_additive", {})
      iam_by_principals     = lookup(v, "iam_by_principals", {})
      ca_pool_config = {
        create_pool = try(v.ca_pool_config.create_pool, null) == null ? null : {
          name = try(v.ca_pool_config.create_pool.name, k)
          enterprise_tier = try(
            v.ca_pool_config.create_pool.enterprise_tier, false
          )
        }
        use_pool = try(v.ca_pool_config.use_pool.id, null) == null ? null : {
          id = v.ca_pool_config.use_pool.id
        }
      }
      ca_configs = {
        for ck, cv in lookup(v, "ca_configs", {}) : ck => merge(cv, {
          key_spec = merge(
            { algorithm = "RSA_PKCS1_2048_SHA256" },
            lookup(cv, "key_spec", {})
          )
          key_usage = merge(
            {
              cert_sign          = true
              client_auth        = false
              code_signing       = false
              content_commitment = false
              crl_sign           = true
              data_encipherment  = false
              decipher_only      = false
              digital_signature  = false
              email_protection   = false
              encipher_only      = false
              key_agreement      = false
              key_encipherment   = true
              ocsp_signing       = false
              server_auth        = true
              time_stamping      = false
            },
            lookup(cv, "key_usage", {})
          )
          subject = merge(
            {
              common_name  = "test.example.com"
              organization = "Test Example"
            },
            lookup(cv, "subject", {})
          )
          subject_alt_name   = lookup(cv, "subject_alt_name", null)
          subordinate_config = lookup(cv, "subordinate_config", null)
        })
      }
    } if lookup(v, "project_id", null) != null
  }
}

module "cas" {
  source                = "../../../modules/certificate-authority-service"
  for_each              = local.ca_pools
  project_id            = each.value.project_id
  location              = each.value.location
  ca_pool_config        = each.value.ca_pool_config
  ca_configs            = each.value.ca_configs
  iam                   = each.value.iam
  iam_bindings          = each.value.iam_bindings
  iam_bindings_additive = each.value.iam_bindings_additive
  iam_by_principals     = each.value.iam_by_principals
  context = merge(local.ctx, {
    project_ids = merge(local.ctx.project_ids, module.factory.project_ids)
  })
  depends_on = [module.factory]
}
