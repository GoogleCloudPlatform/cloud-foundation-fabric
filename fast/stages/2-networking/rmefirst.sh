#!/usr/bin/env bash

# Pure-bash safe script to locate and link existing Stage 0 variable outputs

echo "Locating Stage 0 variables..."

# Find the full path to the Stage 0 output json
FULL_PATH=$(find ~ -name "0-org-setup.auto.tfvars.json" 2>/dev/null | head -n 1)

if [ -z "$FULL_PATH" ]; then
  echo "ERROR: Stage 0 outputs (0-org-setup.auto.tfvars.json) could not be found anywhere under your home directory."
  echo "Please verify if Stage 0 has been applied successfully."
  exit 1
fi

# Extract directories cleanly without complex find -exec syntax
FOUND_DIR=$(dirname "$FULL_PATH")
PARENT_DIR=$(dirname "$FOUND_DIR")

echo "Success: Found Stage 0 outputs at: $PARENT_DIR"

# Clean up existing symlinks
echo "Cleaning existing links in fast/stages/2-networking..."
rm -f *.tfvars *.json *providers.tf

# Link providers
if [ -f "$PARENT_DIR/providers/2-networking-providers.tf" ]; then
  ln -s "$PARENT_DIR/providers/2-networking-providers.tf" ./
  echo "✔ Linked 2-networking-providers.tf"
else
  echo "⚠ Warning: 2-networking-providers.tf was not found under $PARENT_DIR/providers/"
fi

# Link variable JSONs
if [ -f "$FOUND_DIR/0-globals.auto.tfvars.json" ]; then
  ln -s "$FOUND_DIR/0-globals.auto.tfvars.json" ./
  echo "✔ Linked 0-globals.auto.tfvars.json"
fi

if [ -f "$FOUND_DIR/0-org-setup.auto.tfvars.json" ]; then
  ln -s "$FOUND_DIR/0-org-setup.auto.tfvars.json" ./
  echo "✔ Linked 0-org-setup.auto.tfvars.json"
fi

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
echo "  terraform apply"
