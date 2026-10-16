#!/usr/bin/env bash

# Pure-bash safe script to locate and link existing Stage 0 variable outputs

set -euo pipefail

OUTPUTS_BUCKET="gs://placard-prod-iac-core-0-iac-outputs"

echo "Configuring Stage 2 Networking files from ${OUTPUTS_BUCKET}..."

# Clean up existing symlinks
echo "Cleaning existing links in fast/stages/2-networking..."
rm -f *.tfvars *.json *providers.tf

# 1. Copy providers
echo "Copying 2-networking-providers.tf..."
gcloud storage cp "${OUTPUTS_BUCKET}/providers/2-networking-providers.tf" ./providers.tf

# 2. Copy variable JSONs
echo "Copying Stage 0 variable inputs..."
gcloud storage cp "${OUTPUTS_BUCKET}/tfvars/0-globals.auto.tfvars.json" ./
gcloud storage cp "${OUTPUTS_BUCKET}/tfvars/0-org-setup.auto.tfvars.json" ./
gcloud storage cp "${OUTPUTS_BUCKET}/tfvars/1-vpcsc.auto.tfvars.json" ./ 2>/dev/null || true

# Automatically generate the variable file to select the NCC Hub-and-Spoke dataset
# This prevents ephemeral session wipes from resetting Stage 2 back to the VPC Peering default.
echo "Configuring Stage 2 to use the NCC Hub-and-Spoke dataset..."
cat <<EOF > 2-networking.auto.tfvars
factories_config = {
  dataset = "datasets/hub-and-spokes-ncc"
}
EOF
echo "✔ Created 2-networking.auto.tfvars pointing to datasets/hub-and-spokes-ncc"

echo "Done! You can now run:"
echo "  terraform init"
echo "  terraform plan"
