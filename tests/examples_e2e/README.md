Temporary (?) instructions how to set up your environment for E2E tests

# Prerequisites
Prepare following information:
* billing account id
* your organization id
* parent folder under which resources will be created
  * (you may want to disable / restore to default some organization policies under this folder) 
* decide in which region you want to deploy (choose one, that has wide service coverage)
* prepare a prefix, suffix and a timestamp for you (this is to provide project and other resources name uniqueness)
* prepare service account that has necessary permissions (able to assign billing account to project, resource creation etc)

# Option 1 - automatically provision and de-provision testing infrastructure
## Set environmental variables
```bash
export TFTEST_E2E_SERVICE_ACCOUNT=<username>@<project-id>.iam.gserviceaccount.com  # set if you want to use service account impersonation
export TFTEST_E2E_BILLING_ACCOUNT="123456-123456-123456"  # billing account id to associate projects
export TFTEST_E2E_ORGANIZATION_ID="1234567890" # your organization id
export TFTEST_E2E_PARENT="folders/1234567890"  # folder under which test resources will be created
export TFTEST_E2E_PREFIX="your-unique-prefix"  # unique prefix for projects
export TFTEST_E2E_REGION="europe-west4"  # region to use
```

You can keep the prefix the same for all the tests run, the tests will add necessary suffix for subsequent runs, and in case tests are run in parallel, use separate suffix for the workers.
# Run the tests
```bash
pytest tests/examples_e2e
```

# Option 2 - Provision manually test environment and use it for tests
## Provision manually test environment
In `tests/examples_e2e/setup_module` create `terraform.tfvars` with following values:
```hcl
billing_account = "123456-123456-123456"  # billing account id to associate projects
organization_id = "1234567890"  # your organization id
parent          = "folders/1234567890"  # folder under which test resources will be created
prefix          = "your-unique-prefix"  # unique prefix for projects
region          = "europe-west4"  # region to use
suffix          = "1" # suffix, keep 1 for now
timestamp       = "1696444185" # generate your own timestamp - will be used as a part of prefix
# tftest skip
```

If you use service account impersonation, add `proviers.tf` file in `tests/examples_e2e/setup_module`:
```hcl
provider "google" {
  impersonate_service_account = "<username>@<project-id>.iam.gserviceaccount.com"
}

provider "google-beta" {
  impersonate_service_account = "<username>@<project-id>.iam.gserviceaccount.com"
}
# tftest skip
```

In `tests/examples_e2e/setup_module/` run:
```bash
(cd tests/examples_e2e/setup_module/ && terraform apply)
```

This will generate also `tests/examples_e2e/setup_module/e2e_tests.tfvars` for you, which is used by tests.

## Setup your environment
```bash
export TFTEST_E2E_TFVARS_PATH=`pwd`/tests/examples_e2e/setup_module/e2e_tests.tfvars  # generated above
export TFTEST_E2E_SERVICE_ACCOUNT=<username>@<project-id>.iam.gserviceaccount.com  # your service account e-mail to use
```

## Run tests
Run tests using:
```bash
pytest tests/examples_e2e -vv
```
