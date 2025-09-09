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

# tfdoc:file:description Locals for CI/CD workflow files.

locals {
  # render CI/CD workflow templates
  cicd_workflows = {
    for k, v in local.cicd_repositories : "${v.level}-${replace(k, "_", "-")}" => templatefile(
      "${path.module}/templates/workflow-${v.repository.type}.yaml", {
        # If users give a list of custom audiences we set by default the first element.
        # If no audiences are given, we set https://iam.googleapis.com/{PROVIDER_NAME}
        audiences = try(
          local.identity_providers[v.identity_provider].audiences, []
        )
        identity_provider = try(
          local.identity_providers[v.identity_provider].name, ""
        )
        outputs_bucket = var.automation.outputs_bucket
        service_accounts = {
          apply = try(module.cicd-sa-rw[k].email, "")
          plan  = try(module.cicd-sa-ro[k].email, "")
        }
        stage_name = k
        tf_providers_files = {
          apply = replace(local.cicd_workflow_providers[k], "_", "-")
          plan  = replace(local.cicd_workflow_providers["${k}-r"], "_", "-")
        }
        tf_var_files = concat((
          v.level == 2 ?
          [
            "0-bootstrap.auto.tfvars.json",
            "1-resman.auto.tfvars.json",
            "0-globals.auto.tfvars.json"
          ]
          : [
            "0-bootstrap.auto.tfvars.json",
            "0-globals.auto.tfvars.json",
            "1-resman.auto.tfvars.json",
            "2-networking.auto.tfvars.json",
            "2-security.auto.tfvars.json"
          ]
          ),
          v.workflows_config.extra_files
        )
      }
    )
  }
}
