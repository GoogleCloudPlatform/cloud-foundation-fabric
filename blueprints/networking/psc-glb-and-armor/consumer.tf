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

module "consumer-project" {
  source        = "../../../modules/project"
  name          = var.consumer_project_id
  project_reuse = var.project_create_config != null ? null : {}

  billing_account = try(var.project_create_config.billing_account, null)
  parent          = try(var.project_create_config.parent, null)
  prefix          = var.prefix
  services = [
    "iam.googleapis.com",
    "compute.googleapis.com",
  ]
}

module "producer-a" {
  source                = "./modules/producer"
  consumer_project_id   = module.consumer-project.project_id
  prefix                = var.prefix
  producer_project_id   = var.producer_a_project_id
  project_create_config = var.project_create_config
  region                = var.region
}

module "producer-b" {
  source                = "./modules/producer"
  consumer_project_id   = module.consumer-project.project_id
  prefix                = var.prefix
  producer_project_id   = var.producer_b_project_id
  project_create_config = var.project_create_config
  region                = var.region
}

module "consumer-vpc" {
  source = "../../../modules/net-vpc"

  name       = "consumer"
  project_id = module.consumer-project.project_id
  subnets = [
    {
      ip_cidr_range = "10.0.0.0/24"
      name          = "consumer"
      region        = var.region
    },
  ]
}

module "glb" {
  source              = "./../../../modules/net-lb-app-ext"
  name                = "glb"
  project_id          = module.consumer-project.project_id
  use_classic_version = false
  backend_service_configs = {
    default = {
      backends = [
        { backend = "neg-a" }
      ]
      health_checks   = []
      protocol        = "HTTPS"
      security_policy = google_compute_security_policy.cloud-armor-policy.name
    }
    other = {
      backends = [
        { backend = "neg-b" }
      ]
      health_checks   = []
      protocol        = "HTTPS"
      security_policy = google_compute_security_policy.cloud-armor-policy.name
    }
  }
  # with a single serverless NEG the implied default health check is not needed
  health_check_configs = {}
  neg_configs = {
    neg-a = {
      psc = {
        region         = var.region
        target_service = module.producer-a.exposed_service_psc_attachment.self_link
        network        = module.consumer-vpc.id
        subnetwork     = module.consumer-vpc.subnet_ids["${var.region}/consumer"]
      }
    }
    neg-b = {
      psc = {
        region         = var.region
        target_service = module.producer-b.exposed_service_psc_attachment.self_link
        network        = module.consumer-vpc.id
        subnetwork     = module.consumer-vpc.subnet_ids["${var.region}/consumer"]
      }
    }
  }
  urlmap_config = {
    default_service = "default"
    host_rules = [{
      hosts        = ["*"]
      path_matcher = "pathmap"
    }]
    path_matchers = {
      pathmap = {
        default_service = "default"
        path_rules = [
          {
            paths   = ["/b/*"]
            service = "other"
            route_action = {
              url_rewrite = {
                path_prefix = "/" # rewrite "/b/*" to "/*"
              }
            }
          },
          {
            paths   = ["/a/*"]
            service = "default"
            route_action = {
              url_rewrite = {
                path_prefix = "/" # rewrite "/b/*" to "/*"
              }
            }
          },
        ]
      }
    }
  }
}


resource "google_compute_security_policy" "cloud-armor-policy" {
  provider = google-beta
  project  = module.consumer-project.project_id
  name     = "ddos-protection"
  adaptive_protection_config {
    layer_7_ddos_defense_config {
      enable = true
    }
  }
}
