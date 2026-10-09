#!/usr/bin/env bash

# This script grants the necessary Google Cloud IAM roles to justin@placard.media
# so they can navigate, view, and inspect the Network Connectivity Center (NCC) Hub
# hosted in the placard-prod-net-spoke-0 project.

PROD_NET_PROJECT="placard-prod-net-spoke-0"
USER_EMAIL="justin@placard.media"

echo "Granting NCC viewer permissions on project: ${PROD_NET_PROJECT} to: ${USER_EMAIL}..."

# 1. Grant general project-level Viewer permissions (allows console navigation and resource visibility)
gcloud projects add-iam-policy-binding "${PROD_NET_PROJECT}" --member="user:${USER_EMAIL}" --role="roles/viewer"

# 2. Grant Network Connectivity Center Viewer permissions (specific to NCC Hub and Spokes)
gcloud projects add-iam-policy-binding "${PROD_NET_PROJECT}" --member="user:${USER_EMAIL}" --role="roles/networkconnectivity.viewer"

echo "Done! NCC permissions successfully granted."
