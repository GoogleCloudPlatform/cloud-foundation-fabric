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


locals {
  preconfigured_waf_rules = { for k, v in try(var.ext_lb_config.security_policy.preconfigured_waf_rules, {}) : k =>
    merge(v.sensitivity == null ? {} : {
      sensitivity = v.sensitivity
      },
      length(v.opt_in_rule_ids) > 0 ? {
        opt_in_rule_ids = v.opt_in_rule_ids
      } : {},
      length(v.opt_out_rule_ids) > 0 ? {
        opt_out_rule_ids = v.opt_out_rule_ids
    } : {})
  }
  network = try(module.shared_vpc[0].id, module.apigee_vpc[0].id)
  neg_subnets = (var.network_config.shared_vpc == null ?
    (try(var.network_config.apigee_vpc.auto_create, false) ?
      { for k, v in module.apigee_vpc[0].subnets_psc : v.region => v.id } :
    { for k, v in var.network_config.apigee_vpc.subnets_psc : v => v.id }) :
    var.network_config.shared_vpc.subnets_psc
  )
  ilb_subnets = (var.network_config.shared_vpc == null ?
    (try(var.network_config.apigee_vpc.auto_create, false) ?
      { for k, v in module.apigee_vpc[0].subnets : v.region => v.id } :
    { for k, v in var.network_config.apigee_vpc.subnets : v => v.id }) :
    var.network_config.shared_vpc.subnets
  )
  ext_instances              = var.ext_lb_config == null ? {} : { for k, v in local.neg_subnets : k => module.apigee.instances[k] }
  int_instances              = var.int_lb_config == null ? {} : { for k, v in local.ilb_subnets : k => module.apigee.instances[k] }
  int_cross_region_instances = var.int_cross_region_lb_config == null ? {} : { for k, v in local.ilb_subnets : k => module.apigee.instances[k] }
}

resource "google_compute_region_network_endpoint_group" "psc_negs" {
  for_each              = local.neg_subnets
  project               = module.project.project_id
  region                = each.key
  name                  = "apigee-${each.key}"
  network_endpoint_type = "PRIVATE_SERVICE_CONNECT"
  psc_target_service    = module.apigee.instances[each.key].service_attachment
  network               = local.network
  subnetwork            = each.value
}

module "ext_lb" {
  count               = length(local.ext_instances) > 0 ? 1 : 0
  source              = "../../../modules/net-lb-app-ext"
  name                = "ext-lb"
  project_id          = module.project.project_id
  protocol            = "HTTPS"
  address             = var.ext_lb_config.address
  use_classic_version = false
  backend_service_configs = {
    default = {
      backends          = [for k, v in local.ext_instances : { backend = google_compute_region_network_endpoint_group.psc_negs[k].id }]
      protocol          = "HTTPS"
      health_checks     = []
      outlier_detection = var.ext_lb_config.outlier_detection
      security_policy   = try(google_compute_security_policy.policy[0].name, null)
      log_sample_rate   = var.ext_lb_config.log_sample_rate
    }
  }
  ssl_certificates = var.ext_lb_config.ssl_certificates
}

module "int_lb" {
  for_each   = local.int_instances
  source     = "../../../modules/net-lb-app-int"
  name       = "${each.key}-int-lb"
  project_id = module.project.project_id
  region     = each.key
  protocol   = "HTTPS"
  address    = try(var.int_lb_config.addresses[each.key], null)
  backend_service_configs = {
    default = {
      backends = [{
        group = google_compute_region_network_endpoint_group.psc_negs[each.key].id
      }]
      outlier_detection = var.int_lb_config.outlier_detection
      health_checks     = []
      log_sample_rate   = var.int_lb_config.log_sample_rate
    }
  }
  ssl_certificates = var.int_lb_config.ssl_certificates
  vpc_config = {
    network    = local.network
    subnetwork = local.ilb_subnets[each.key]
  }
}

module "certificate_manager" {
  count              = length(local.int_cross_region_instances) > 0 ? 1 : 0
  source             = "../../../modules/certificate-manager"
  project_id         = module.project.project_id
  certificates       = var.int_cross_region_lb_config.certificate_manager_config.certificates
  dns_authorizations = var.int_cross_region_lb_config.certificate_manager_config.dns_authorizations
  issuance_configs   = var.int_cross_region_lb_config.certificate_manager_config.issuance_configs
}

module "int_cross_region_lb" {
  count      = length(local.int_cross_region_instances) > 0 ? 1 : 0
  source     = "../../../modules/net-lb-app-int-cross-region"
  name       = "int-cross-region-lb"
  project_id = module.project.project_id
  protocol   = "HTTPS"
  addresses  = var.int_cross_region_lb_config.addresses
  backend_service_configs = {
    default = {
      backends = [for k, v in google_compute_region_network_endpoint_group.psc_negs : {
        group = v.id
      }]
      outlier_detection = var.int_cross_region_lb_config.outlier_detection
      health_checks     = []
      log_sample_rate   = var.int_cross_region_lb_config.log_sample_rate
    }
  }
  https_proxy_config = {
    certificate_manager_certificates = (var.int_cross_region_lb_config == null ?
      null :
    values(module.certificate_manager[0].certificate_ids))
  }
  vpc_config = {
    network     = local.network
    subnetworks = local.ilb_subnets
  }
}

resource "google_compute_security_policy" "policy" {
  provider    = google-beta
  count       = try(var.ext_lb_config.security_policy, null) == null ? 0 : 1
  name        = "cloud-armor-security-policy"
  description = "Cloud Armor Security Policy"
  project     = module.project.project_id
  dynamic "advanced_options_config" {
    for_each = try(var.ext_lb_config, null) == null ? [] : [""]
    content {
      json_parsing = try(var.ext_lb_config.security_policy.adaptive_protection_config.json_parsing.enable, false) ? "DISABLED" : "STANDARD"
      dynamic "json_custom_config" {
        for_each = try(var.ext_lb_config.security_policy.adaptive_protection_config.json_parsing.content_types, null) == null ? [] : [""]
        content {
          content_types = var.ext_lb_config.security_policy.adaptive_protection_config.json_parsing.content_types
        }
      }
      log_level = var.ext_lb_config.security_policy.advanced_options_config.log_level
    }
  }
  dynamic "adaptive_protection_config" {
    for_each = try(var.ext_lb_config.security_policy.adaptive_protection_config, null) == null ? [] : [""]
    content {
      dynamic "layer_7_ddos_defense_config" {
        for_each = try(var.ext_lb_config.security_policy.adaptive_protection_config.layer_7_ddos_defense_config, null) == null ? [] : [""]
        content {
          enable          = var.ext_lb_config.security_policy.adaptive_protection_config.layer_7_ddos_defense_config.enable
          rule_visibility = var.ext_lb_config.security_policy.adaptive_protection_config.layer_7_ddos_defense_config.rule_visibility
        }
      }
      dynamic "auto_deploy_config" {
        for_each = try(var.int_lb_config.security_policy.adaptive_protection_config.auto_deploy_config, null) == null ? [] : [""]
        content {
          load_threshold              = var.ext_lb_config.security_policy.adaptive_protection_config.auto_deploy_config.load_threshold
          confidence_threshold        = var.ext_lb_config.security_policy.adaptive_protection_config.auto_deploy_config.confidence_threshold
          impacted_baseline_threshold = var.ext_lb_config.security_policy.adaptive_protection_config.auto_deploy_config.impacted_baseline_threshold
          expiration_sec              = var.ext_lb_config.security_policy.adaptive_protection_config.auto_deploy_config.expiration_sec
        }
      }
    }
  }
  type = "CLOUD_ARMOR"
  dynamic "rule" {
    for_each = try(var.ext_lb_config.security_policy.rate_limit_threshold, null) == null ? [] : [""]
    content {
      action   = "throttle"
      priority = 3000
      rate_limit_options {
        enforce_on_key = "ALL"
        conform_action = "allow"
        exceed_action  = "deny(429)"
        rate_limit_threshold {
          count        = var.ext_lb_config.security_policy.rate_limit_threshold.count
          interval_sec = var.ext_lb_config.security_policy.rate_limit_threshold.interval_sec
        }
      }
      match {
        versioned_expr = "SRC_IPS_V1"
        config {
          src_ip_ranges = ["*"]
        }
      }
      description = "Rate limit all user IPs"
    }
  }
  dynamic "rule" {
    for_each = try(length(var.ext_lb_config.security_policy.forbidden_src_ip_ranges), 0) > 0 ? [""] : []
    content {
      action   = "deny(403)"
      priority = 5000
      match {
        versioned_expr = "SRC_IPS_V1"
        config {
          src_ip_ranges = var.ext_lb_config.security_policy.forbidden_src_ip_ranges
        }
      }
      description = "Deny access to IPs in specific ranges"
    }
  }
  dynamic "rule" {
    for_each = try(length(var.ext_lb_config.security_policy.forbidden_regions), 0) > 0 ? [""] : []
    content {
      action   = "deny(403)"
      priority = 7000
      match {
        expr {
          expression = "origin.region_code.matches(\"^${join("|", var.ext_lb_config.security_policy.forbidden_regions)}$\")"
        }
      }
      description = "Block users from forbidden regions"
    }
  }
  dynamic "rule" {
    for_each = local.preconfigured_waf_rules
    content {
      action   = "deny(403)"
      priority = 10000 + index(keys(var.ext_lb_config.security_policy.preconfigured_waf_rules), rule.key) * 1000
      match {
        expr {
          expression = "evaluatePreconfiguredWaf(\"${rule.key}\"${length(rule.value) > 0 ? join("", [",", jsonencode(rule.value)]) : ""})"
        }
      }
      description = "Preconfigured WAF rule (${rule.key})"
    }
  }
  rule {
    action   = "allow"
    priority = 2147483647
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "default rule"
  }
}
