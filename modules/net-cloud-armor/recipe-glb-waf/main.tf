/**
 * Copyright 2026 Google LLC
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
  geo_expression = join(" && ", [
    for c in var.geo_allowlist : "origin.region_code != '${c}'"
  ])
  waf_rules = {
    for i, rs in var.waf_config.rule_sets : "waf-${rs}" => {
      priority = 1000 + i
      action   = "deny(403)"
      preview  = var.waf_config.preview
      match = {
        expression = "evaluatePreconfiguredWaf('${rs}', {'sensitivity': ${var.waf_config.sensitivity}})"
      }
    }
  }
}

module "project" {
  source = "../../../modules/project"
  name   = var.project_id
  project_reuse = {
    use_data_source = var._testing == null
    attributes      = var._testing
  }
  services = [
    "compute.googleapis.com",
    "run.googleapis.com"
  ]
}

module "cloud-run" {
  source     = "../../../modules/cloud-run-v2"
  project_id = module.project.id
  name       = "${var.name}-app"
  region     = var.region
  containers = {
    hello = {
      image = "us-docker.pkg.dev/cloudrun/container/hello"
    }
  }
  iam = {
    "roles/run.invoker" = var.invoker_members
  }
  service_config = {
    ingress = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
  }
  deletion_protection = false
}

module "bucket" {
  source     = "../../../modules/gcs"
  project_id = module.project.id
  name       = "${var.name}-static"
  location   = var.region
  iam = {
    "roles/storage.objectViewer" = ["allUsers"]
  }
}

# backend security policy: WAF, geo allowlist, rate limiting, L7 DDoS defense

module "waf" {
  source     = "../../../modules/net-cloud-armor"
  project_id = module.project.id
  name       = "${var.name}-waf"
  adaptive_protection_config = {
    layer_7_ddos_defense = {}
  }
  advanced_options_config = {
    json_parsing = "STANDARD"
  }
  rules = merge(
    local.waf_rules,
    {
      throttle = {
        priority = 100
        action   = "throttle"
        match = {
          src_ip_ranges = ["*"]
        }
        rate_limit_options = {
          exceed_action  = "deny(429)"
          enforce_on_key = "IP"
          rate_limit_threshold = {
            count        = var.rate_limit.count
            interval_sec = var.rate_limit.interval_sec
          }
        }
      }
    },
    local.geo_expression == "" ? {} : {
      geo-allowlist = {
        priority = 500
        action   = "deny(403)"
        match = {
          expression = local.geo_expression
        }
      }
    }
  )
}

# edge security policy: enforced upstream of the CDN cache for static assets

module "edge" {
  source     = "../../../modules/net-cloud-armor"
  project_id = module.project.id
  name       = "${var.name}-edge"
  type       = "CLOUD_ARMOR_EDGE"
  rules = local.geo_expression == "" ? {} : {
    geo-allowlist = {
      priority = 500
      action   = "deny(403)"
      match = {
        expression = local.geo_expression
      }
    }
  }
}

module "glb" {
  source     = "../../../modules/net-lb-app-ext"
  project_id = module.project.id
  name       = var.name
  backend_buckets_config = {
    static = {
      bucket_name          = module.bucket.name
      enable_cdn           = true
      edge_security_policy = module.edge.id
    }
  }
  backend_service_configs = {
    default = {
      backends        = [{ group = "app" }]
      health_checks   = []
      security_policy = module.waf.id
    }
  }
  health_check_configs = {}
  neg_configs = {
    app = {
      cloudrun = {
        region = var.region
        target_service = {
          name = module.cloud-run.service_name
        }
      }
    }
  }
  urlmap_config = {
    default_service = "default"
    host_rules = [{
      hosts        = ["*"]
      path_matcher = "default"
    }]
    path_matchers = {
      default = {
        default_service = "default"
        path_rules = [{
          paths   = ["/static", "/static/*"]
          service = "static"
        }]
      }
    }
  }
}
