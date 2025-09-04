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

moved {
  from = module.organization.google_organization_iam_custom_role.roles
  to   = module.organization.0.google_organization_iam_custom_role.roles
}

moved {
  from = module.organization.google_logging_organization_sink.sink
  to   = module.organization-iam.0.google_logging_organization_sink.sink
}

moved {
  from = module.organization.google_org_policy_custom_constraint.constraint
  to   = module.organization.0.google_org_policy_custom_constraint.constraint
}

moved {
  from = module.organization.google_org_policy_policy.default
  to   = module.organization-iam.0.google_org_policy_policy.default
}

moved {
  from = module.organization.google_tags_tag_key.default["org-policies"]
  to   = module.organization.0.google_tags_tag_key.default["org-policies"]
}

moved {
  from = module.organization.google_tags_tag_value.default
  to   = module.organization.0.google_tags_tag_value.default
}

moved {
  from = module.organization.google_logging_organization_settings.default
  to   = module.organization[0].google_logging_organization_settings.default
}

moved {
  from = module.automation-project
  to   = module.factory.module.projects["iac-0"]
}
