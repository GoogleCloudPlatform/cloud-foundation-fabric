Temporary (?) instructions how to set up your environment for E2E tests

# Step 1 - Prerequisites
Prepare following information:
* billing account id
* your organization id
* parent folder under which resources will be created
  * (you may want to disable / restore to default some organization policies under this folder) 
* decide in which region you want to deploy (choose one, that has wide service coverage)
* prepare a prefix, suffix and a timestamp for you (this is to provide project and other resources name uniqueness)
* prepare service account that has necessary permissions (able to assign billing account to project, resource creation etc)

# Step 2 - Provide your values to Terraform
In `tests/examples_e2e/setup_module` create `terraform.tfvars with following values:
```hcl
billing_account = "123456-123456-123456"  # billing account id to associate projects
organization_id = "1234567890"  # your organization id
parent          = "folders/1234567890"  # folder under which test resources will be created
prefix          = "your-unique-prefix"  # unique prefix for projects
region          = "europe-west4"  # region to use
suffix          = "1" # suffix, keep 1 for now
timestamp       = "1696444185" # generate your own timestamp - will be used as a part of prefix
```

Create `tests/examples_e2e/setup_module/providers.tf`  file with following content
```hcl
provider "google" {
  impersonate_service_account = "<username>@<project-id>>.iam.gserviceaccount.com"
}

provider "google-beta" {
  impersonate_service_account = "<username>@<project-id>.iam.gserviceaccount.com"
}
```

# Step 3 - Create bootstrap infra
In `tests/examples_e2e/setup_module/` run:
`terraform apply`

This will generate also `tests/examples_e2e/terraform.tfvars` for you, which is used by tests.

# Step 4 - Create providers file for tests
Use the same Service account for tests
```
cp tests/examples_e2e/setup_module/providers.tf tests/examples_e2e/providers.tf
```

# Step 5 - Play with tests
Run tests using:
```
pytest tests/examples_e2e -vv
```
