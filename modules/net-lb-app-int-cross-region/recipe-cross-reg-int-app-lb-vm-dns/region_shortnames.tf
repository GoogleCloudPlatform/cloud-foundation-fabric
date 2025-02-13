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

# tfdoc:file:description Region shortnames via locals.

# adapted from FAST networking stages

locals {
  # used when the first character would not work
  _region_cardinal = {
    southeast = "se"
  }
  _region_geo = {
    australia = "o"
  }
  # split in [geo, cardinal, number] tokens
  _region_tokens = {
    for v in local.regions : v => regexall("(?:[a-z]+)|(?:[0-9]+)", v)
  }
  region_shortnames = {
    for k, v in local._region_tokens : k => join("", [
      # first token via geo alias map or first character
      lookup(local._region_geo, v[0], substr(v[0], 0, 1)),
      # first token via cardinal alias map or first character
      lookup(local._region_cardinal, v[1], substr(v[1], 0, 1)),
      # region number as is
      v[2]
    ])
  }
}
