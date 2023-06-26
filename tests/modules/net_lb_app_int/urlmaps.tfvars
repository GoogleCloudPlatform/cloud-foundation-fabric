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

backend_service_configs = {
  default = {
    backends = [{
      group = "projects/myprj/zones/europe-west1-a/instanceGroups/my-ig"
    }]
  }
  video = {
    backends = [{
      group = "projects/myprj/zones/europe-west1-a/instanceGroups/my-ig-2"
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
      path_rules = [{
        paths   = ["/video", "/video/*"]
        service = "video"
      }]
      route_rules = [{
        priority = 1
        service  = "default"
        match_rules = [{
          ignore_case = true
        }]
        url_redirect = {
          host  = "foo.example.org"
          https = true
          path  = "/foo"
        }
      }]
    }
  }
}
