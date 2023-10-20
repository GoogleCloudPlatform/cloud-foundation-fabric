# Prerequisites
Prepare following information:
* billing account id
* your organization id
* parent folder under which resources will be created
  * (you may want to disable / restore to default some organization policies under this folder) 
* decide in which region you want to deploy (choose one, that has wide service coverage)
* prepare a prefix, suffix and a timestamp for you (this is to provide project and other resources name uniqueness)
* prepare service account that has necessary permissions (able to assign billing account to project, resource creation etc)

# How does it work
Each test case is provided by additional environment defined in [variables.tf](./variables.tf). This simplifies writing the examples as this follows the same structure as for non-end-to-end tests, and allows multiple, independent and concurrent runs of tests.

The test environment can be provisioned automatically during the test run (which now takes ~2 minutes) and destroyed and the end, when of the tests (Option 1 below), which is targeting automated runs in CI/CD pipeline, or can be provisioned manually to reduce test time, which might be typical use case for tests run locally.

# Option 1 - automatically provision and de-provision testing infrastructure

## Create `e2e.tfvars` file
```hcl
billing_account = "123456-123456-123456"  # billing account id to associate projects
organization_id = "1234567890" # your organization id
parent          = "folders/1234567890"  # folder under which test resources will be created
prefix          = "your-unique-prefix"  # unique prefix for projects
region          = "europe-west4"  # region to use

# tftest skip
```
And set environment variable pointing to the file:
```bash
export TFTEST_E2E_SETUP_TFVARS_PATH=<path to e2e.tfvars file>
```

Or set above variables in environment:
```bash
export TF_VAR_billing_account="123456-123456-123456"  # billing account id to associate projects
export TF_VAR_organization_id="1234567890" # your organization id
export TF_VAR_parent="folders/1234567890"  # folder under which test resources will be created
export TF_VAR_prefix="your-unique-prefix"  # unique prefix for projects
export TF_VAR_region="europe-west4"  # region to use
```

To use Service Account Impersonation, use provider environment variable
```bash
export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=<username>@<project-id>.iam.gserviceaccount.com
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

If you use service account impersonation, set `GOOGLE_IMPERSONATE_SERVICE_ACCOUNT`
```bash
export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=<username>@<project-id>.iam.gserviceaccount.com
```

Provision the environment using terraform
```bash
(cd tests/examples_e2e/setup_module/ && terraform init && terraform apply)
```

This will generate also `tests/examples_e2e/setup_module/e2e_tests.tfvars` for you, which can be used by tests.

## Setup your environment
```bash
export TFTEST_E2E_TFVARS_PATH=`pwd`/tests/examples_e2e/setup_module/e2e_tests.tfvars  # generated above
```

## Run tests
Run tests using:
```bash
pytest tests/examples_e2e
```
