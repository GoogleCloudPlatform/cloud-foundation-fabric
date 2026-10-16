#!/usr/bin/env bash
# Pure-bash safe script to locate and link existing Stage 0, 1, and 2 variable outputs

set -euo pipefail

OUTPUTS_BUCKET="gs://placard-prod-iac-core-0-iac-outputs"

echo "Configuring Stage 2 Project Factory files from ${OUTPUTS_BUCKET}..."

# Clean up existing symlinks / stale files
rm -f *.tfvars *.json *providers.tf

# 1. Copy provider configuration
echo "Copying 2-project-factory-providers.tf..."
gcloud storage cp "${OUTPUTS_BUCKET}/providers/2-project-factory-providers.tf" ./providers.tf

# 2. Copy dependencies
echo "Copying stage input variables..."
gcloud storage cp "${OUTPUTS_BUCKET}/tfvars/0-globals.auto.tfvars.json" ./
gcloud storage cp "${OUTPUTS_BUCKET}/tfvars/0-org-setup.auto.tfvars.json" ./

# 3. Copy optional networking & security inputs if they exist
gcloud storage cp "${OUTPUTS_BUCKET}/tfvars/1-vpcsc.auto.tfvars.json" ./ 2>/dev/null || true
gcloud storage cp "${OUTPUTS_BUCKET}/tfvars/2-networking.auto.tfvars.json" ./ 2>/dev/null || true
gcloud storage cp "${OUTPUTS_BUCKET}/tfvars/2-security.auto.tfvars.json" ./ 2>/dev/null || true

echo "✔ Successfully configured provider and variable files."
echo "Done! You can now run:"
echo "  terraform init"
echo "  terraform plan"
