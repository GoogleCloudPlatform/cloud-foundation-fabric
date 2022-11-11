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
  vpc_sc_access_levels = {
    onprem = {
      conditions = [{
        ip_subnetworks = ["101.101.101.0/24"]
      }]
    }
  }
  vpc_sc_egress_policies = {
    iac-gcs = {
      from = {
        identities = [
          "serviceAccount:xxx-prod-resman-security-0@xxx-prod-iac-core-0.iam.gserviceaccount.com"
        ]
      }
      to = {
        operations = [{
          method_selectors = ["*"]
          service_name     = "storage.googleapis.com"
        }]
        resources = ["projects/123456782"]
      }
    }
  }
  vpc_sc_ingress_policies = {
    iac = {
      from = {
        identities = [
          "serviceAccount:xxx-prod-resman-security-0@xxx-prod-iac-core-0.iam.gserviceaccount.com"
        ]
        access_levels = ["*"]
      }
      to = {
        operations = [{ method_selectors = [], service_name = "*" }]
        resources  = ["*"]
      }
    }
  }
  vpc_sc_perimeters = {
    dev = {
      egress_policies  = ["iac-gcs"]
      ingress_policies = ["iac"]
      resources        = ["projects/1111111111"]
    }
    dev = {
      egress_policies  = ["iac-gcs"]
      ingress_policies = ["iac"]
      resources        = ["projects/0000000000"]
    }
    dev = {
      access_levels    = ["onprem"]
      egress_policies  = ["iac-gcs"]
      ingress_policies = ["iac"]
      resources        = ["projects/2222222222"]
    }
  }
}
