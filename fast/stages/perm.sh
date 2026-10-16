#!/usr/bin/env bash
# Copyright 2026 Placard Media / Cloud Foundation Fabric
#
# Remediation script to grant:
# 1. serviceUsageConsumer to iac-org-rw and iac-org-ro on placard-prod-iac-core-0
#    (resolves 403 querying Cloud Storage / serviceusage.services.use during terraform init)
# 2. Stage 0 management roles to iac-org-rw
# 3. Impersonation and project access roles to Tessa (tessa@placard.media / tessa@placard.com)

set -euo pipefail

PROJECT_ID="placard-prod-iac-core-0"
OUTPUTS_BUCKET="placard-prod-iac-core-0-iac-outputs"

echo "========================================================================"
echo " Placard Media - IAM Remediation for ${PROJECT_ID}"
echo "========================================================================"
echo ""

# 0. Check and ensure valid gcloud authentication
echo "[0/4] Checking gcloud authentication..."
CURRENT_ACCOUNT=$(gcloud config get-value account 2>/dev/null || true)

if ! gcloud auth print-access-token &>/dev/null; then
  echo "  Active account [${CURRENT_ACCOUNT:-none}] credentials are expired or invalid."
  echo "  Launching 'gcloud auth login' to authenticate with an admin account (e.g. justin@placard.media)..."
  gcloud auth login
  CURRENT_ACCOUNT=$(gcloud config get-value account 2>/dev/null)
fi
echo "  ✓ Authenticated as: ${CURRENT_ACCOUNT}"
echo ""

# 1. Fix Service Usage Consumer on Stage 0 Service Accounts
echo "[1/4] Granting 'roles/serviceusage.serviceUsageConsumer' to Stage 0 Service Accounts..."
for sa in "iac-org-rw" "iac-org-ro"; do
  SA_EMAIL="${sa}@${PROJECT_ID}.iam.gserviceaccount.com"
  echo "  -> Adding role on ${SA_EMAIL}..."
  gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/serviceusage.serviceUsageConsumer" \
    --condition=None
done
echo "  ✓ Done."
echo ""

# 2. Stage 0 core management roles on iac-org-rw
echo "[2/4] Granting core management roles to iac-org-rw..."
SA_ORG_RW="iac-org-rw@${PROJECT_ID}.iam.gserviceaccount.com"
for role in \
  roles/cloudbuild.builds.editor \
  roles/iam.serviceAccountAdmin \
  roles/iam.workloadIdentityPoolAdmin \
  roles/owner \
  roles/storage.admin; do
  echo "  -> Adding ${role}..."
  gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="serviceAccount:${SA_ORG_RW}" \
    --role="${role}" \
    --condition=None
done
echo "  ✓ Done."
echo ""

# 3. Grant impersonation and quota permissions to Tessa
echo "[3/4] Granting impersonation and access permissions to Tessa..."
TESSA_ACCOUNTS=("tessa@placard.media" "tessa@placard.com")

for user in "${TESSA_ACCOUNTS[@]}"; do
  echo "  Checking and granting permissions for user:${user}..."

  # Allow setting quota project and calling APIs
  gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="user:${user}" \
    --role="roles/serviceusage.serviceUsageConsumer" \
    --condition=None || true

  # Allow impersonating service accounts (Token Creator)
  gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="user:${user}" \
    --role="roles/iam.serviceAccountTokenCreator" \
    --condition=None || true

  # Allow project metadata and bucket inspection
  gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="user:${user}" \
    --role="roles/viewer" \
    --condition=None || true

  # Direct read access to outputs bucket for fast-links.sh
  gcloud storage buckets add-iam-policy-binding "gs://${OUTPUTS_BUCKET}" \
    --member="user:${user}" \
    --role="roles/storage.objectViewer" || true
done
echo "  ✓ Done."
echo ""

# 4. Verify the fix in IAM policy
echo "[4/4] Verifying 'serviceusage.serviceUsageConsumer' on iac-org-rw..."
if gcloud projects get-iam-policy "${PROJECT_ID}" --flatten="bindings[].members" \
  --filter="bindings.members:iac-org-rw@ AND bindings.role:roles/serviceusage.serviceUsageConsumer" \
  --format="value(bindings.role)" | grep -q "serviceUsageConsumer"; then
  echo "  ✓ CONFIRMED: iac-org-rw has roles/serviceusage.serviceUsageConsumer on ${PROJECT_ID}."
else
  echo "  ✗ WARNING: Verification check did not see the binding. Please check output above."
fi

echo ""
echo "========================================================================"
echo " All IAM bindings successfully configured and verified!"
echo "========================================================================"
