#!/usr/bin/env bash

# JRE Bootstrapping Script for placard.media

# 1. Define variables based on your placard-lz tfvars
export FAST_ORG_ID="150829647948"

# Google Cloud validates that a Group exists in Cloud Identity/Workspace before allowing it to be bound to IAM policies.
# If you haven't created the 'gcp-org-admins@placard.media' group in admin.google.com yet,
# we default to using your currently logged-in individual gcloud user account:
ACTIVE_USER=$(gcloud config get-value account 2>/dev/null)
export FAST_PRINCIPAL="user:${ACTIVE_USER}"

echo "Using Active Principal: ${FAST_PRINCIPAL}"

# To switch back to using the group once it has been created, uncomment this line:
# export FAST_PRINCIPAL="group:gcp-org-admins@placard.media"

# 2. Define the required bootstrapping roles
export FAST_ROLES="
  roles/billing.admin
  roles/logging.admin
  roles/iam.organizationRoleAdmin
  roles/orgpolicy.policyAdmin
  roles/resourcemanager.folderAdmin
  roles/resourcemanager.organizationAdmin
  roles/resourcemanager.projectCreator
  roles/resourcemanager.tagAdmin
  roles/owner
"

# 3. Apply the IAM policy bindings at the organization level
for role in $FAST_ROLES; do
  echo "Adding role $role to $FAST_PRINCIPAL at organization level..."
  gcloud organizations add-iam-policy-binding "$FAST_ORG_ID" --member "$FAST_PRINCIPAL" --role "$role" --condition None
done

# 4. Assign Billing Account Permissions
# If the billing account 011375-A0472C-432D72 is externally
# managed (e.g., owned by a reseller or parent org instead of
# being organization-contained), organization-level bindings
# won't automatically propagate. Make sure the executing
# principal has the Billing Account Administrator
# (roles/billing.admin) role bound directly on the billing
# account:
echo "Adding billing.admin role on billing account 011375-A0472C-432D72..."
gcloud billing accounts add-iam-policy-binding "011375-A0472C-432D72" --member "$FAST_PRINCIPAL" --role "roles/billing.admin"

# 5. Setup a Quota-Tracking Project (If starting fresh)
# To prevent failures related to API usage limits/quota tracking
# when managing Org Policies, ensure your active gcloud
# configuration points to a billing-enabled project with the
# necessary APIs enabled:

# Set a default project for quota tracking
echo "Setting default project for quota tracking..."
gcloud config set project intrepid-fiber-506711-j5

# Enable prerequisite APIs in that project
echo "Enabling prerequisite APIs..."
gcloud services enable bigquery.googleapis.com cloudbilling.googleapis.com cloudresourcemanager.googleapis.com essentialcontacts.googleapis.com iam.googleapis.com logging.googleapis.com orgpolicy.googleapis.com serviceusage.googleapis.com
