# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module "xlb" {
  for_each            = toset(var.global_lb ? [""] : [])
  source              = "../../../modules/net-lb-app-ext"
  project_id          = module.project.project_id
  name                = var.lb_name
  use_classic_version = false
  backend_service_configs = {
    python-backend = {
      backends = [
        { backend = "python-backend-neg" },
      ]
      health_checks = []
      port_name     = "http"
    }
  }
  backend_buckets_config = {
    gcs-static = {
      bucket_name = module.bucket.name
    }
  }
  health_check_configs = {}

  urlmap_config = {
    default_service = "gcs-static"
    host_rules = [{
      hosts        = ["*"]
      path_matcher = "api"
    }]
    path_matchers = {
      api = {
        default_service = "gcs-static"
        route_rules = [
          {
            description = "Send all backend traffic to our Cloud Function"
            match_rules = [
              {
                path = {
                  value = "/api/"
                  type  = "prefix"
                }
              }
            ]
            service  = "python-backend"
            priority = 50
          },
          {
            description = "Passthrough all static assets to the bucket"
            match_rules = [
              {
                path = {
                  value = "/*.ico"
                  type  = "template"
                }
              },
              {
                path = {
                  value = "/*.png"
                  type  = "template"
                }
              },
              {
                path = {
                  value = "/*.json"
                  type  = "template"
                }
              },
              {
                path = {
                  value = "/*.txt"
                  type  = "template"
                }
              },
              {
                path = {
                  value = "/*.css"
                  type  = "template"
                }
              },
              {
                path = {
                  value = "/*.js"
                  type  = "template"
                }
              },
            ]
            service = "gcs-static"
            header_action = {
              response_add = {
                "Content-Security-Policy" = {
                  value = local.csp_header
                }
              }
            }
            priority = 60
          },
          {
            description = "Rewrite all non-static requests to index.html"
            match_rules = [
              {
                path = {
                  value = "/**"
                  type  = "template"
                }
              }
            ]
            service  = "gcs-static"
            priority = 100
            header_action = {
              response_add = {
                "Content-Security-Policy" = {
                  value = local.csp_header
                }
              }
            }
            route_action = {
              url_rewrite = {
                path_template = "/index.html"
              }
            }
          }
        ]
      }
    }
  }

  neg_configs = {
    python-backend-neg = {
      cloudrun = {
        region = var.region
        target_service = {
          name = module.backend.function_name
        }
      }
    }
  }
}
