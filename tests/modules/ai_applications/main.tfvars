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

name       = "my-chat-app"
project_id = "test-project"

data_stores_configs = {
  data-store-1 = {
    solution_types = ["SOLUTION_TYPE_CHAT"]
  }
}

engines_configs = {
  data_store_ids = ["data-store-1"]
  chat_engine_config = {
    company_name          = "Google"
    default_language_code = "en"
    time_zone             = "America/Los_Angeles"
  }
}
