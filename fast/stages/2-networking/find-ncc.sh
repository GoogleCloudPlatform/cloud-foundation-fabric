#!/usr/bin/env bash

# This script automatically searches across all three core FAST networking projects
# to locate which project is hosting the active Network Connectivity Center (NCC) Hub.

echo "=========================================================="
echo "🔍 Searching for the NCC Hub across your networking projects"
echo "=========================================================="

PROJECTS=(
  "placard-prod-net-core-0"
  "placard-prod-net-spoke-0"
  "placard-dev-net-spoke-0"
)

# Loop through each project and run the gcloud list command
for project in "${PROJECTS[@]}"; do
  echo -e "\n----------------------------------------------------------"
  echo "Checking project: ${project} ..."
  gcloud network-connectivity hubs list --project="${project}"
done

echo -e "\n----------------------------------------------------------"
echo "Done searching."
