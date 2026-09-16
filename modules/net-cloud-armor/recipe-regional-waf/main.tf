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

module "vpc" {
  source     = "../../../modules/net-vpc"
  project_id = module.project.id
  name       = var.name
  subnets = [
    {
      ip_cidr_range = var.vpc_config.subnet_cidr
      name          = "${var.name}-default"
      region        = var.region
    }
  ]
  subnets_proxy_only = [
    {
      ip_cidr_range = var.vpc_config.proxy_only_cidr
      name          = "${var.name}-proxy"
      region        = var.region
    }
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

# a single regional backend security policy, shared by the external
# and internal Application Load Balancers

module "waf" {
  source     = "../../../modules/net-cloud-armor"
  project_id = module.project.id
  region     = var.region
  name       = "${var.name}-waf"
  rules = merge(
    local.waf_rules,
    length(var.trusted_ranges) == 0 ? {} : {
      allow-trusted = {
        priority = 100
        action   = "allow"
        match = {
          src_ip_ranges = var.trusted_ranges
        }
      }
    }
  )
}

module "ralb" {
  source     = "../../../modules/net-lb-app-ext-regional"
  project_id = module.project.id
  region     = var.region
  name       = "${var.name}-ext"
  vpc_config = {
    network = module.vpc.self_link
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
  depends_on = [module.vpc]
}

module "ilb" {
  source     = "../../../modules/net-lb-app-int"
  project_id = module.project.id
  region     = var.region
  name       = "${var.name}-int"
  vpc_config = {
    network    = module.vpc.self_link
    subnetwork = module.vpc.subnet_self_links["${var.region}/${var.name}-default"]
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
  depends_on = [module.vpc]
}
