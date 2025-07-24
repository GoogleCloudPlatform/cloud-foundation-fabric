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

# tfdoc:file:description Billing budget factory locals.

module "billing-budgets" {
  source = "../billing-account"
  count  = var.factories_config.budgets != null ? 1 : 0
  id     = var.factories_config.budgets.billing_account
  context = merge(local.ctx, {
    folder_ids  = merge(local.ctx.folder_ids, local.folder_ids)
    project_ids = local.project_ids
  })
  factories_config = {
    budgets_data_path = var.factories_config.budgets.data_path
  }
}
