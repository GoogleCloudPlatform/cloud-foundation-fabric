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

output "id" {
  description = "Fully qualified logging bucket id."
  value       = local.bucket.id
}

output "view_ids" {
  description = "The automatic and user-created views in this bucket."
  value = merge(
    {
      for k, v in google_logging_log_view.views :
      k => v.id
    },
    {
      "_AllLogs" = "${local.bucket.id}/views/_AllLogs"
    }
  )
}
