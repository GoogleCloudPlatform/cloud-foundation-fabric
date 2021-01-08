# Usage

/!\ Requires Terraform version 12.20 at least. Visit https://releases.hashicorp.com/terraform/ to get it.

You need to add your own `terraform.tfvars` with the following values:
``` terraform
organization_id = "<YOUR ORG ID>"
billing_account = "<YOUR BILLING ACCOUNT ID>"
```

You should create a `backend.tf` file with the following configuration:
``` terraform
provider "google" {
  version = "~> 3.51.0"
}

provider "google-beta" {
  version = "~> 3.51.0"
}

terraform {
  backend "gcs" {
    bucket = "<YOUR BUCKET FOR THE TERRAFORM STATE>"
    prefix = "<NAME FOR THE TERRAFORM STATE FOLDER>"
  }
}
```

TO avoid dependency issues, use the following commands to create the modules in the correct order:
``` bash
tf apply -target module.project-service-1 -target module.project-service-2
tf apply -target module.vpc
tf apply
```

# Testing

Optionally, you can rename `test.example` into `test.tf`.
This file will create 2 VM instances and corresponding DNS records so you can easily test this solution.

# Clean Up

Run `terraform destroy` to clean up all resources created by this terraform code.

There's a minor glitch that can surface running `terraform destroy`, where the service project attachments to the Shared VPC will not get destroyed even with the relevant API call succeeding. We are investigating the issue, in the meantime just manually remove the attachment in the Cloud console or via the `gcloud beta compute shared-vpc associated-projects remove` command when `terraform destroy` fails, and then relaunch the command.

Command to delete lien:
``` bash
gcloud alpha resource-manager liens delete `gcloud alpha resource-manager liens list --project PROJECT_ID --format="value(name)"`
```


# Errors

Error: Error creating Network: googleapi: Error 404: The resource 'projects/test-dns2afd-appteam2' was not found, notFound



Error: Error when reading or editing Project Service : Request "List Project Services test-dns2afd-appteam1" returned error: Batch request and retried single request "List Project Services test-dns2afd-appteam1" both failed. Final error: Failed to list enabled services for project test-dns2afd-appteam1: googleapi: Error 403: Project 'test-dns2afd-appteam1' not found or permission denied., forbidden



Error: Error when reading or editing Project Service : Request "List Project Services test-dns2afd-appteam2" returned error: Batch request and retried single request "List Project Services test-dns2afd-appteam2" both failed. Final error: Failed to list enabled services for project test-dns2afd-appteam2: googleapi: Error 403: Project 'test-dns2afd-appteam2' not found or permission denied., forbidden



Error: Error when reading or editing Project Service : Request "List Project Services test-dns2afd-appteam1" returned error: Batch request and retried single request "List Project Services test-dns2afd-appteam1" both failed. Final error: Failed to list enabled services for project test-dns2afd-appteam1: googleapi: Error 403: Project 'test-dns2afd-appteam1' not found or permission denied., forbidden



Error: Error creating Network: googleapi: Error 404: The resource 'projects/test-dns2afd-appteam1' was not found, notFound



Error: Error when reading or editing Project Service : Request "List Project Services test-dns2afd-appteam2" returned error: Batch request and retried single request "List Project Services test-dns2afd-appteam2" both failed. Final error: Failed to list enabled services for project test-dns2afd-appteam2: googleapi: Error 403: Project 'test-dns2afd-appteam2' not found or permission denied., forbidden
