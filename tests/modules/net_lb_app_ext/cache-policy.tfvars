# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

name                = "glb-test-0"
project_id          = "my-project"
use_classic_version = false

backend_service_configs = {
  default = {
    backends = [{
      group = "projects/my-project/zones/europe-west8-b/instanceGroups/ig-b"
    }]
    enable_cdn = true
  }
}

urlmap_config = {
  default_service = "default"
  default_route_action = {
    cache_policy = {
      cache_mode       = "CACHE_ALL_STATIC"
      default_ttl      = 3600
      negative_caching = true
    }
  }
  host_rules = [
    {
      hosts        = ["*"]
      path_matcher = "paths"
    },
    {
      hosts        = ["api.example.org"]
      path_matcher = "routes"
    }
  ]
  path_matchers = {
    paths = {
      default_service = "default"
      default_route_action = {
        cache_policy = {
          cache_mode = "USE_ORIGIN_HEADERS"
          cache_key_policy = {
            include_host     = true
            include_protocol = false
          }
        }
      }
      path_rules = [{
        paths   = ["/static/*"]
        service = "default"
        route_action = {
          cache_policy = {
            cache_mode  = "FORCE_CACHE_ALL"
            client_ttl  = 0
            default_ttl = 86400
            cache_key_policy = {
              included_query_parameters = ["v"]
            }
          }
        }
      }]
    }
    routes = {
      default_service = "default"
      route_rules = [{
        priority = 1
        service  = "default"
        match_rules = [{
          path = {
            value = "/api/"
          }
        }]
        route_action = {
          cache_policy = {
            cache_bypass_request_header_names = ["Authorization"]
            cache_mode                        = "CACHE_ALL_STATIC"
            client_ttl                        = 60
            default_ttl                       = 120
            max_ttl                           = 600
            negative_caching                  = true
            request_coalescing                = false
            serve_while_stale                 = 0
            cache_key_policy = {
              excluded_query_parameters = ["session"]
              include_query_string      = true
              included_cookie_names     = ["lang"]
              included_header_names     = ["X-Client"]
            }
            negative_caching_policy = [
              { code = 404, ttl = 300 },
              { code = 410, ttl = 60 }
            ]
          }
        }
      }]
    }
  }
}
