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

locals {
  _datascan_specs = {
    for f in fileset(var.datascan_spec_folder, "**/*.yaml") :
    replace(trimsuffix(f, ".yaml"), "/", "-") => yamldecode(file("${var.datascan_spec_folder}/${f}"))
  }

  _datascan_rule_templates = yamldecode(file(var.datascan_rule_templates_file_path))

  _datascan_defaults = yamldecode(file(var.datascan_defaults_file_path))

  datascans = {
    for datascan_name, datascan_configs in local._resolved_datascan_rules :
    datascan_name => {
      prefix             = try(datascan_configs.prefix, null)
      labels             = try(datascan_configs.labels, null)
      execution_schedule = try(datascan_configs.execution_schedule, null)
      data               = datascan_configs.data
      incremental_field  = try(datascan_configs.incremental_field, null)
      data_quality_spec  = try(datascan_configs.data_quality_spec, null)
      data_profile_spec  = try(datascan_configs.data_profile_spec, null)
      iam_bindings       = datascan_configs.iam_bindings
    }
  }
}

module "dataplex-datascan" {
  source             = "../../../modules/dataplex-datascan"
  for_each           = local.datascans
  project_id         = var.project_id
  region             = var.region
  name               = each.key
  prefix             = each.value.prefix
  labels             = each.value.labels
  execution_schedule = each.value.execution_schedule
  data               = each.value.data
  incremental_field  = each.value.incremental_field
  data_quality_spec  = each.value.data_quality_spec
  data_profile_spec  = each.value.data_profile_spec
  iam_bindings       = each.value.iam_bindings
}
