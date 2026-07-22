#!/usr/bin/env bash

export FAST_PRINCIPAL="group:gcp-organization-admins@stayhome-ai.com"
export FAST_ORG_ID=15122406886
export FAST_ROLES="\
  roles/billing.admin \
  roles/logging.admin \
  roles/iam.organizationRoleAdmin \
  roles/orgpolicy.policyAdmin \
  roles/resourcemanager.folderAdmin \
  roles/resourcemanager.organizationAdmin \
  roles/resourcemanager.projectCreator \
  roles/resourcemanager.tagAdmin \
  roles/owner"

for role in $FAST_ROLES; do
  gcloud organizations add-iam-policy-binding $FAST_ORG_ID \
    --member $FAST_PRINCIPAL --role $role --condition None
done
