/**
 * Copyright 2025 Google LLC
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

output "ids" {
  description = "Aspect type IDs."
  value = {
    for k, v in google_dataplex_aspect_type.default : k => v.id
  }
  depends_on = [
    google_dataplex_aspect_type_iam_binding.authoritative,
    google_dataplex_aspect_type_iam_binding.bindings,
    google_dataplex_aspect_type_iam_member.members
  ]
}

output "names" {
  description = "Aspect type names."
  value = {
    for k, v in google_dataplex_aspect_type.default : k => v.name
  }
  depends_on = [
    google_dataplex_aspect_type_iam_binding.authoritative,
    google_dataplex_aspect_type_iam_binding.bindings,
    google_dataplex_aspect_type_iam_member.members
  ]
}

output "timestamps" {
  description = "Aspect type create and update timestamps."
  value = {
    for k, v in google_dataplex_aspect_type.default : k => {
      create = v.create_time
      update = v.update_time
    }
  }
  depends_on = [
    google_dataplex_aspect_type_iam_binding.authoritative,
    google_dataplex_aspect_type_iam_binding.bindings,
    google_dataplex_aspect_type_iam_member.members
  ]
}

output "uids" {
  description = "Aspect type gobally unique IDs."
  value = {
    for k, v in google_dataplex_aspect_type.default : k => v.uid
  }
  depends_on = [
    google_dataplex_aspect_type_iam_binding.authoritative,
    google_dataplex_aspect_type_iam_binding.bindings,
    google_dataplex_aspect_type_iam_member.members
  ]
}
