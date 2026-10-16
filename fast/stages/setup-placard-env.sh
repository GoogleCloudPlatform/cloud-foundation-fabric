#!/usr/bin/env bash
# Copyright 2026 Placard Media / Cloud Foundation Fabric
#
# Automated Environment Onboarding Script for Placard Media Team Members
# Configures gcloud CLI, Application Default Credentials (ADC), Quota Project,
# and verifies Service Account Impersonation for Google Foundation Fabric (FAST).

set -euo pipefail

# ANSI color codes for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m' # No Color

CORE_PROJECT="placard-prod-iac-core-0"
OUTPUTS_BUCKET="gs://placard-prod-iac-core-0-iac-outputs"

echo -e "${BLUE}${BOLD}================================================================${NC}"
echo -e "${BLUE}${BOLD}   Placard Media - Google Foundation Fabric Team Onboarding     ${NC}"
echo -e "${BLUE}${BOLD}================================================================${NC}"
echo ""

# 1. Verify Prerequisites
echo -e "${BOLD}[1/5] Checking prerequisites...${NC}"

if ! command -v gcloud &>/dev/null; then
  echo -e "${RED}ERROR: 'gcloud' CLI is not installed.${NC}"
  echo "Please install the Google Cloud SDK: https://cloud.google.com/sdk/docs/install"
  exit 1
fi
echo -e "  ${GREEN}✓${NC} gcloud CLI found: $(gcloud version 2>&1 | head -n 1)"

if ! command -v terraform &>/dev/null; then
  echo -e "${YELLOW}WARNING: 'terraform' CLI is not found in PATH.${NC}"
  echo "You will need Terraform (>= 1.5.0) or OpenTofu to manage infrastructure."
else
  echo -e "  ${GREEN}✓${NC} Terraform found: $(terraform version 2>&1 | head -n 1)"
fi
echo ""

# 2. Check Active gcloud Account
echo -e "${BOLD}[2/5] Checking active gcloud account...${NC}"
CURRENT_ACCOUNT=$(gcloud config get-value account 2>/dev/null || true)

if [[ -z "${CURRENT_ACCOUNT}" || "${CURRENT_ACCOUNT}" == "(unset)" ]]; then
  echo -e "${YELLOW}No active gcloud account detected. Initiating authentication...${NC}"
  gcloud auth login
  CURRENT_ACCOUNT=$(gcloud config get-value account)
fi

echo -e "  Active account: ${BOLD}${CURRENT_ACCOUNT}${NC}"

if [[ "${CURRENT_ACCOUNT}" != *"@placard.media" ]]; then
  echo -e "${YELLOW}WARNING: Active account is not a '@placard.media' account.${NC}"
  read -r -p "Do you want to re-authenticate with your placard.media account? (y/N): " REAUTH
  if [[ "${REAUTH}" =~ ^[Yy]$ ]]; then
    gcloud auth login
    CURRENT_ACCOUNT=$(gcloud config get-value account)
  fi
fi
echo -e "  ${GREEN}✓${NC} Authenticated as: ${BOLD}${CURRENT_ACCOUNT}${NC}"
echo ""

# 3. Check and Configure Application Default Credentials (ADC)
echo -e "${BOLD}[3/5] Configuring Application Default Credentials (ADC)...${NC}"
ADC_PATH="${HOME}/.config/gcloud/application_default_credentials.json"

ADC_EMAIL=""
if [[ -f "${ADC_PATH}" ]]; then
  ADC_TOKEN=$(gcloud auth application-default print-access-token 2>/dev/null || true)
  if [[ -n "${ADC_TOKEN}" ]]; then
    ADC_EMAIL=$(curl -s "https://oauth2.googleapis.com/tokeninfo?access_token=${ADC_TOKEN}" 2>/dev/null \
      | grep -o '"email": *"[^"]*"' | head -n 1 | cut -d'"' -f4 || true)
  fi
fi

if [[ -z "${ADC_EMAIL}" || "${ADC_EMAIL}" != "${CURRENT_ACCOUNT}" ]]; then
  if [[ -n "${ADC_EMAIL}" ]]; then
    echo -e "  ${YELLOW}Notice:${NC} Current ADC account (${ADC_EMAIL}) does not match active gcloud account (${CURRENT_ACCOUNT})."
  else
    echo -e "  ${YELLOW}Notice:${NC} Application Default Credentials (ADC) are not configured."
  fi
  echo "  Launching 'gcloud auth application-default login' to authenticate ADC as ${CURRENT_ACCOUNT}..."
  gcloud auth application-default login
fi
echo -e "  ${GREEN}✓${NC} ADC credential file verified: ${ADC_PATH}"

# Set Quota Project
echo "  Configuring API Quota Project: ${CORE_PROJECT}..."
gcloud config set project "${CORE_PROJECT}" --quiet
if ! gcloud auth application-default set-quota-project "${CORE_PROJECT}" --quiet 2>/dev/null; then
  echo -e "  ${YELLOW}Notice:${NC} Retrying quota project configuration with updated credentials..."
  gcloud auth application-default login
  gcloud auth application-default set-quota-project "${CORE_PROJECT}" --quiet
fi
echo -e "  ${GREEN}✓${NC} Quota project successfully set to: ${BOLD}${CORE_PROJECT}${NC}"
echo ""

# 4. Service Account Impersonation Verification
echo -e "${BOLD}[4/5] Selecting FAST Stage to verify Impersonation...${NC}"
echo "Available Stages:"
echo "  1) Stage 2: Networking     (iac-networking-ro / iac-networking-rw)"
echo "  2) Stage 2: Security       (iac-security-ro / iac-security-rw)"
echo "  3) Stage 2: Project Factory(iac-pf-ro / iac-pf-rw)"
echo "  4) Stage 1: VPC-SC         (iac-vpcsc-ro / iac-vpcsc-rw)"
echo "  5) Stage 0: Org Setup      (iac-org-ro / iac-org-rw)"
echo ""

read -r -p "Enter choice [1-5] (default: 1): " STAGE_CHOICE
STAGE_CHOICE="${STAGE_CHOICE:-1}"

case "${STAGE_CHOICE}" in
  1)
    TARGET_SA="iac-networking-ro@${CORE_PROJECT}.iam.gserviceaccount.com"
    STAGE_DIR="fast/stages/2-networking"
    ;;
  2)
    TARGET_SA="iac-security-ro@${CORE_PROJECT}.iam.gserviceaccount.com"
    STAGE_DIR="fast/stages/2-security"
    ;;
  3)
    TARGET_SA="iac-pf-ro@${CORE_PROJECT}.iam.gserviceaccount.com"
    STAGE_DIR="fast/stages/2-project-factory"
    ;;
  4)
    TARGET_SA="iac-vpcsc-ro@${CORE_PROJECT}.iam.gserviceaccount.com"
    STAGE_DIR="fast/stages/1-vpcsc"
    ;;
  5)
    TARGET_SA="iac-org-ro@${CORE_PROJECT}.iam.gserviceaccount.com"
    STAGE_DIR="fast/stages/0-org-setup"
    ;;
  *)
    TARGET_SA="iac-networking-ro@${CORE_PROJECT}.iam.gserviceaccount.com"
    STAGE_DIR="fast/stages/2-networking"
    ;;
esac

echo ""
echo "Testing token creation for: ${TARGET_SA}..."
if TOKEN=$(gcloud auth print-access-token --impersonate-service-account="${TARGET_SA}" 2>/dev/null); then
  echo -e "  ${GREEN}✓ SUCCESS!${NC} Ephemeral access token minted successfully."
  echo "    Token prefix: ${TOKEN:0:15}..."
else
  echo -e "  ${RED}✗ FAILED:${NC} Unable to impersonate ${TARGET_SA}."
  echo ""
  echo "Common reasons:"
  echo "  1. Your account (${CURRENT_ACCOUNT}) has not been added to the required Google Group."
  echo "  2. The Google Group has not been granted 'roles/iam.serviceAccountTokenCreator' on the SA."
  echo "  3. Service usage consumer permission is missing on ${CORE_PROJECT}."
  echo ""
  echo "Please contact Justin Evans (justin@placard.media) with your email and the target stage."
  exit 1
fi
echo ""

# 5. Verify Outputs Bucket Access
echo -e "${BOLD}[5/5] Checking GCS Outputs Bucket access...${NC}"
if gcloud storage ls "${OUTPUTS_BUCKET}" &>/dev/null; then
  echo -e "  ${GREEN}✓ SUCCESS!${NC} Can read ${OUTPUTS_BUCKET}"
else
  echo -e "  ${YELLOW}Notice:${NC} Direct GCS bucket listing restricted (normal if using backend impersonation)."
fi

echo ""
echo -e "${GREEN}${BOLD}================================================================${NC}"
echo -e "${GREEN}${BOLD}   Setup Complete! You are ready to run Terraform.             ${NC}"
echo -e "${GREEN}${BOLD}================================================================${NC}"
echo ""
echo "Next steps:"
echo -e "  1. Navigate to your stage: ${BOLD}cd ${STAGE_DIR}${NC}"
echo -e "  2. Link provider configs:  ${BOLD}../fast-links.sh ${OUTPUTS_BUCKET} | bash${NC}"
echo -e "  3. Initialize backend:     ${BOLD}terraform init${NC}"
echo -e "  4. Plan changes:           ${BOLD}terraform plan${NC}"
echo ""
