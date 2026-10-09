#!/usr/bin/env bash

# This script manually assigns the serviceusage.serviceUsageConsumer role to
# all stage service accounts to prevent 403 Permission Denied errors on
# GCS state backend access during 'terraform init'.

PROJECT_ID="placard-prod-iac-core-0"

echo "Force-setting active gcloud project to: ${PROJECT_ID}..."
gcloud config set project "${PROJECT_ID}"

# Export environment variables for the current session to override any old session caches
export GOOGLE_PROJECT="${PROJECT_ID}"
export GOOGLE_CLOUD_PROJECT="${PROJECT_ID}"

echo "Adding serviceusage consumer role on project: ${PROJECT_ID}..."

# Stage 2 - Networking
echo "Applying Stage 2 - Networking..."
gcloud projects add-iam-policy-binding "${PROJECT_ID}" --member="serviceAccount:iac-networking-rw@${PROJECT_ID}.iam.gserviceaccount.com" --role="roles/serviceusage.serviceUsageConsumer"
gcloud projects add-iam-policy-binding "${PROJECT_ID}" --member="serviceAccount:iac-networking-ro@${PROJECT_ID}.iam.gserviceaccount.com" --role="roles/serviceusage.serviceUsageConsumer"

# Stage 2 - Security
echo "Applying Stage 2 - Security..."
gcloud projects add-iam-policy-binding "${PROJECT_ID}" --member="serviceAccount:iac-security-rw@${PROJECT_ID}.iam.gserviceaccount.com" --role="roles/serviceusage.serviceUsageConsumer"
gcloud projects add-iam-policy-binding "${PROJECT_ID}" --member="serviceAccount:iac-security-ro@${PROJECT_ID}.iam.gserviceaccount.com" --role="roles/serviceusage.serviceUsageConsumer"

# Stage 2 - Project Factory
echo "Applying Stage 2 - Project Factory..."
gcloud projects add-iam-policy-binding "${PROJECT_ID}" --member="serviceAccount:iac-pf-rw@${PROJECT_ID}.iam.gserviceaccount.com" --role="roles/serviceusage.serviceUsageConsumer"
gcloud projects add-iam-policy-binding "${PROJECT_ID}" --member="serviceAccount:iac-pf-ro@${PROJECT_ID}.iam.gserviceaccount.com" --role="roles/serviceusage.serviceUsageConsumer"

# Stage 1 - VPC Service Controls
echo "Applying Stage 1 - VPC Service Controls..."
gcloud projects add-iam-policy-binding "${PROJECT_ID}" --member="serviceAccount:iac-vpcsc-rw@${PROJECT_ID}.iam.gserviceaccount.com" --role="roles/serviceusage.serviceUsageConsumer"
gcloud projects add-iam-policy-binding "${PROJECT_ID}" --member="serviceAccount:iac-vpcsc-ro@${PROJECT_ID}.iam.gserviceaccount.com" --role="roles/serviceusage.serviceUsageConsumer"

# Enable logging.googleapis.com on the networking projects to prevent Terraform plan failures
# This resolves the data source chicken-and-egg bug where Terraform tries to read logging settings before the API is enabled
echo "--------------------------------------------------------"
echo "Enabling logging.googleapis.com on networking projects..."
echo "--------------------------------------------------------"
gcloud services enable logging.googleapis.com --project="placard-prod-net-core-0"
gcloud services enable logging.googleapis.com --project="placard-prod-net-spoke-0"
gcloud services enable logging.googleapis.com --project="placard-dev-net-spoke-0"

# Import already existing projects into Terraform state to resolve 409 Already Exists errors
# This happens because the projects were partially created on Google Cloud before the billing quota errored out,
# preventing the state from saving. This adopts them cleanly back into the Terraform state.
echo "--------------------------------------------------------"
echo "Cleaning existing project and legacy network records from state..."
echo "--------------------------------------------------------"
terraform state rm 'module.projects.module.projects["net-core-0"].google_project.project[0]' || true
terraform state rm 'module.projects.module.projects["net-dev-0"].google_project.project[0]' || true
terraform state rm 'module.projects.module.projects["net-prod-0"].google_project.project[0]' || true

# Clean up legacy Belgium/VPC Peering Router NATs and Routers from state
# This resolves the connection-refused/location-policy-violated errors caused by the deleted europe-west1 resources
terraform state rm 'module.vpc-factory.google_compute_router_nat.default["dev/nat-primary"]' || true
terraform state rm 'module.vpc-factory.google_compute_router_nat.default["prod/nat-primary"]' || true
terraform state rm 'module.vpc-factory.google_compute_router.default["dev/nat-primary"]' || true
terraform state rm 'module.vpc-factory.google_compute_router.default["prod/nat-primary"]' || true

echo "--------------------------------------------------------"
echo "Checking if we need to import existing projects into Terraform state..."
echo "--------------------------------------------------------"

# Run import commands (using || true so the script continues if a project doesn't exist yet)
# Note: The project ID for 'net-prod-0' is 'placard-prod-net-spoke-0' (not 'placard-prod-net-prod-0')
terraform import 'module.projects.module.projects["net-core-0"].google_project.project[0]' placard-prod-net-core-0 || true
terraform import 'module.projects.module.projects["net-dev-0"].google_project.project[0]' placard-dev-net-spoke-0 || true
terraform import 'module.projects.module.projects["net-prod-0"].google_project.project[0]' placard-prod-net-spoke-0 || true

echo "Done! All configurations and imports successfully handled."
