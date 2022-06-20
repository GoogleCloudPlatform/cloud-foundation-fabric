/**
 * Copyright 2022 Google LLC
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

module "stage" {
  source = "../../../../../fast/stages/02-security"
  automation = {
    outputs_bucket = "test"
  }
  billing_account = {
    id              = "000000-111111-222222"
    organization_id = 123456789012
  }
  custom_roles = {
    cloud_kms_key_editor = "cloudKmsKeyAdmin"
  }
  folder_ids = {
    security = null
  }
  organization = {
    domain      = "gcp-pso-italy.net"
    id          = 856933387836
    customer_id = "C01lmug8b"
  }
  prefix = "fast"
  kms_keys = {
    compute = {
      iam = {
        "roles/cloudkms.admin" = ["user:user1@example.com"]
      }
      labels          = { service = "compute" }
      locations       = null
      rotation_period = null
    }
  }
  service_accounts = {
    security             = "foobar@iam.gserviceaccount.com"
    data-platform-dev    = "foobar@iam.gserviceaccount.com"
    data-platform-prod   = "foobar@iam.gserviceaccount.com"
    project-factory-dev  = "foobar@iam.gserviceaccount.com"
    project-factory-prod = "foobar@iam.gserviceaccount.com"
  }
  vpc_sc_ingress_policies = {
    iac = {
      ingress_from = {
        identities = [
          "serviceAccount:fast-prod-resman-security-0@fast-prod-iac-core-0.iam.gserviceaccount.com"
        ],
        source_access_levels = ["*"], identity_type = null, source_resources = null
      }
      ingress_to = {
        operations = [{ method_selectors = [], service_name = "*" }]
        resources  = ["*"]
      }
    }
  }
  vpc_sc_perimeter_ingress_policies = {
    dev     = ["iac"]
    landing = null
    prod    = ["iac"]
  }
  vpc_sc_perimeter_projects = {
    dev = [
      "projects/345678912", # ludo-dev-sec-core-0
    ]
    landing = []
    prod = [
      "projects/234567891", # ludo-prod-sec-core-0
    ]
  }

  vpc_sc_access_levels = {
    all = {
      combining_function = null
      conditions = [{
        members = [
          "serviceAccount:quota-monitor@foobar.iam.gserviceaccount.com",
        ],
        ip_subnetworks         = null, negate = null, regions = null,
        required_access_levels = null
      }]
    }
  }

  vpc_sc_perimeter_access_levels = {
    dev     = ["all"]
    landing = null
    prod    = ["all"]
  }

  vpc_sc_egress_policies = {
    iac-gcs = {
      egress_from = {
        identity_type = null
        identities = [
          "serviceAccount:fast-prod-resman-security-0@fast-prod-iac-core-0.iam.gserviceaccount.com"
        ]
      }
      egress_to = {
        operations = [{
          method_selectors = ["*"], service_name = "storage.googleapis.com"
        }]
        resources = ["projects/123456789"]
      }
    }
  }
}
