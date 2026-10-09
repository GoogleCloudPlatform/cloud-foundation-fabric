#!/usr/bin/env bash

# Pure-bash safe script to locate and link existing Stage variables for Stage 3 Workload deployments

echo "Locating Stage variables..."

# Find the full path to the Stage 0 output json
FULL_PATH=$(find ~ -name "0-org-setup.auto.tfvars.json" 2>/dev/null | head -n 1)

if [ -z "$FULL_PATH" ]; then
  echo "ERROR: Stage 0 outputs (0-org-setup.auto.tfvars.json) could not be found anywhere under your home directory."
  echo "Please verify if Stage 0 has been applied successfully."
  exit 1
fi

FOUND_DIR=$(dirname "$FULL_PATH")

echo "Success: Found Stage variables at: $FOUND_DIR"

# Clean up existing symlinks
echo "Cleaning existing links in fast/stages/3-workloads..."
rm -f *.tfvars *.json

# Link variable JSONs containing project IDs and subnet self-links
if [ -f "$FOUND_DIR/0-org-setup.auto.tfvars.json" ]; then
  ln -s "$FOUND_DIR/0-org-setup.auto.tfvars.json" ./
  echo "✔ Linked 0-org-setup.auto.tfvars.json"
fi

if [ -f "$FOUND_DIR/2-networking.auto.tfvars.json" ]; then
  ln -s "$FOUND_DIR/2-networking.auto.tfvars.json" ./
  echo "✔ Linked 2-networking.auto.tfvars.json (Networking)"
fi

# Automatically generate 3-workloads.auto.tfvars to define our project ID mapping and Workload Factories
# This provides you with a ready-to-run template containing your London Linux/Windows VMs, NY/LA templates, and GCS Bucket resources.
echo "Generating 3-workloads.auto.tfvars..."
cat << 'EOF' > 3-workloads.auto.tfvars
# -----------------------------------------------------------------------------
# Stage 3 Workloads Configuration Map
# -----------------------------------------------------------------------------

# 1. Project mapping (from previous steps)
project_ids = {
  lon-dev-project-0 = "placard-lon-dev-project-0"
  ny-dev-project-0  = "placard-ny-dev-project-0"
  la-dev-project-0  = "placard-la-dev-project-0"
}

# 2. Map-driven VM Factory (Add as many VMs as you want here!)
compute_instances = {
  # Your London Debian Linux VM with billing labels
  "lon-dev-debian-micro" = {
    project_key  = "lon-dev-project-0"
    machine_type = "e2-micro"          # Cost-efficient, free-tier eligible
    zone         = "europe-west2-a"    # London, UK
    image        = "projects/debian-cloud/global/images/family/debian-12"
    vpc_key      = "london"
    subnet_key   = "europe-west2/subnet-london"
    labels = {
      environment = "dev"
      team        = "naeu-london"
      billing     = "placard-media"
      os          = "linux"
    }
  }

  # Your London Windows Server GUI VM with billing labels
  # Note: This is Windows Server 2022 with Desktop Experience (GUI) to enable standard
  # visual Remote Desktop (RDP) sessions. We use e2-medium (2 vCPUs, 4GB RAM) as the 
  # cost-efficient minimum to run the GUI comfortably with a 50GB boot disk.
  "lon-dev-windows-micro" = {
    project_key  = "lon-dev-project-0"
    machine_type = "e2-medium"       # Minimum comfortable instance size for Windows
    zone         = "europe-west2-a"  # London, UK
    image        = "projects/windows-cloud/global/images/family/windows-2022" # Standard Server 2022 with Desktop Experience (GUI)
    vpc_key      = "london"
    subnet_key   = "europe-west2/subnet-london"
    size         = 50               # Recommended minimum Windows boot disk size
    labels = {
      environment = "dev"
      team        = "naeu-london"
      billing     = "placard-media"
      os          = "windows"
    }
  }

  # EXAMPLE: Adding a New York Spoke VM! (Deploys in its own dedicated NY project)
  "ny-dev-debian-micro" = {
    project_key  = "ny-dev-project-0"
    machine_type = "e2-micro"
    zone         = "us-east1-b"     # New York / us-east1
    vpc_key      = "new-york"
    subnet_key   = "us-east1/subnet-newyork"
    labels = {
      environment = "dev"
      team        = "naeu-newyork"
      billing     = "placard-media"
      os          = "linux"
    }
  }

  # EXAMPLE: Adding a Los Angeles Spoke VM! (Deploys in its own dedicated LA project)
  "la-dev-debian-micro" = {
    project_key  = "la-dev-project-0"
    machine_type = "e2-micro"
    zone         = "us-west2-a"     # Los Angeles / us-west2
    vpc_key      = "los-angeles"
    subnet_key   = "us-west2/subnet-losangeles"
    labels = {
      environment = "dev"
      team        = "naeu-losangeles"
      billing     = "placard-media"
      os          = "linux"
    }
  }
}

# 3. Map-driven GCS Bucket Factory (Add as many buckets as you want here!)
gcs_buckets = {
  "placard-dev-media-uploads-bucket" = {
    project_key = "lon-dev-project-0"
    location    = "europe-west2"    # London GCS region
    class       = "STANDARD"
    labels = {
      environment = "dev"
      team        = "naeu-london"
      billing     = "placard-media"
    }
  }
}
EOF
echo "✔ Created 3-workloads.auto.tfvars with project_ids and factories mapping containing billing labels"

echo "Done! Stage 3 Workload links and variables successfully created."
