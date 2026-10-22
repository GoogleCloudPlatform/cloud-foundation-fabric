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

project_id = "test-project"
region     = "europe-west1"
name       = "test-lb"
vpc_config = {
  network = "projects/test-project/global/networks/test-vpc"
}
http_proxy_config = {
  name                   = "custom-http-proxy"
  http_keepalive_timeout = 610
}
backend_service_configs = {
  default = {
    backends = [{
      group = "projects/test-project/zones/europe-west1-b/instanceGroups/ig-b"
    }]
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
      header_action = {
        request_remove  = ["X-Remove-Req"]
        response_remove = ["X-Remove-Resp"]
        request_add = {
          X-Add-Req = {
            value   = "req-val"
            replace = true
          }
        }
        response_add = {
          X-Add-Resp = {
            value   = "resp-val"
            replace = false
          }
        }
      }
      path_rules = [{
        paths   = ["/api", "/api/*"]
        service = "default"
        route_action = {
          cors_policy = {
            allow_headers        = ["Authorization", "Content-Type"]
            allow_methods        = ["GET", "OPTIONS"]
            allow_origin_regexes = ["https://.*\\.example\\.org"]
            expose_headers       = ["X-Path-Header"]
          }
        }
      }]
      route_rules = [{
        priority = 1
        service  = "default"
        match_rules = [{
          ignore_case = true
        }]
        route_action = {
          cors_policy = {
            allow_credentials = true
            allow_headers     = ["X-Route-Header"]
            allow_methods     = ["GET", "POST"]
            allow_origins     = ["https://app.example.org"]
            expose_headers    = ["X-Route-Expose"]
            max_age           = "3600"
          }
        }
      }]
    }
  }
}
