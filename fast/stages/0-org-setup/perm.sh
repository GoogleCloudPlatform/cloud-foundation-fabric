#!/usr/bin/env bash
# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -euo pipefail

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Grants the initial IAM roles required to run the 0-org-setup stage.

Options:
  -o, --org-id ORG_ID            Google Cloud Organization ID (numeric).
                                 Can also be set via FAST_ORG_ID env var.
  -p, --principal PRINCIPAL      IAM member to grant roles to.
                                 e.g. user:alice@example.com, group:gcp-organization-admins@example.com
                                 Can also be set via FAST_PRINCIPAL env var.
                                 Defaults to: user:\$(gcloud config get-value account)
  -b, --billing-account ID       (Optional) Billing Account ID (e.g. 012345-678901-ABCDEF)
                                 to grant roles/billing.admin on an external billing account.
  -h, --help                     Display this help message and exit.

Examples:
  $(basename "$0") -o 123456789012 -p user:admin@example.com
  $(basename "$0") -o 123456789012 -p group:gcp-organization-admins@example.com -b 012345-678901-ABCDEF
EOF
}

ORG_ID="${FAST_ORG_ID:-}"
PRINCIPAL="${FAST_PRINCIPAL:-}"
BILLING_ACCOUNT="${FAST_BILLING_ACCOUNT_ID:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--org-id)
      ORG_ID="$2"
      shift 2
      ;;
    -p|--principal)
      PRINCIPAL="$2"
      shift 2
      ;;
    -b|--billing-account)
      BILLING_ACCOUNT="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

# If principal is not specified, attempt to infer from gcloud active account
if [[ -z "$PRINCIPAL" ]]; then
  CURRENT_ACCOUNT=$(gcloud config get-value account 2>/dev/null || true)
  if [[ -n "$CURRENT_ACCOUNT" ]]; then
    PRINCIPAL="user:${CURRENT_ACCOUNT}"
    echo "Principal not specified. Defaulting to active gcloud account: ${PRINCIPAL}"
  else
    echo "Error: Principal must be specified via -p/--principal or FAST_PRINCIPAL env var." >&2
    usage
    exit 1
  fi
fi

# Ensure principal has a valid prefix
if [[ ! "$PRINCIPAL" =~ ^(user|group|serviceAccount): ]]; then
  echo "Warning: Principal '${PRINCIPAL}' has no prefix. Assuming 'user:${PRINCIPAL}'."
  PRINCIPAL="user:${PRINCIPAL}"
fi

# If org-id is not specified, attempt to detect if there is only one organization
if [[ -z "$ORG_ID" ]]; then
  ORGS=$(gcloud organizations list --format="value(ID)" 2>/dev/null || true)
  ORG_COUNT=$(echo "$ORGS" | grep -c . || true)
  if [[ "$ORG_COUNT" -eq 1 ]]; then
    ORG_ID="$ORGS"
    echo "Organization ID not specified. Detected single organization: ${ORG_ID}"
  else
    echo "Error: Organization ID must be specified via -o/--org-id or FAST_ORG_ID env var." >&2
    echo "Available organizations:" >&2
    gcloud organizations list >&2 || true
    exit 1
  fi
fi

# Prerequisite roles required for FAST 0-org-setup
FAST_ROLES=(
  "roles/billing.admin"
  "roles/logging.admin"
  "roles/iam.organizationRoleAdmin"
  "roles/orgpolicy.policyAdmin"
  "roles/resourcemanager.folderAdmin"
  "roles/resourcemanager.organizationAdmin"
  "roles/resourcemanager.projectCreator"
  "roles/resourcemanager.tagAdmin"
  "roles/owner"
)

echo "============================================================"
echo "Granting FAST 0-org-setup prerequisite roles"
echo "Organization: ${ORG_ID}"
echo "Principal:    ${PRINCIPAL}"
echo "============================================================"

for role in "${FAST_ROLES[@]}"; do
  echo "Granting ${role} on organizations/${ORG_ID}..."
  gcloud organizations add-iam-policy-binding "${ORG_ID}" \
    --member="${PRINCIPAL}" \
    --role="${role}" \
    --condition=None \
    --quiet >/dev/null
done

if [[ -n "$BILLING_ACCOUNT" ]]; then
  echo "Granting roles/billing.admin on billingAccounts/${BILLING_ACCOUNT}..."
  gcloud billing accounts add-iam-policy-binding "${BILLING_ACCOUNT}" \
    --member="${PRINCIPAL}" \
    --role="roles/billing.admin" \
    --condition=None \
    --quiet >/dev/null
fi

echo "============================================================"
echo "Successfully granted all prerequisite roles to ${PRINCIPAL}."
echo "You can now run 'terraform apply' in 0-org-setup."
echo "============================================================"
