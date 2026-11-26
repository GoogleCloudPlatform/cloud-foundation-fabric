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

set -eo pipefail

GITHUB_ORG="${GITHUB_ORG:-}"
APP_ID="${GITHUB_APP_ID:-}"
INSTALLATION_ID="${GITHUB_APP_INSTALLATION_ID:-}"
PRIVATE_KEY_PATH="${GITHUB_APP_PRIVATE_KEY_PATH:-/secrets/github-app-private-key}"
RUNNER_GROUP_ID="${RUNNER_GROUP_ID:-1}"
RUNNER_LABELS="${RUNNER_LABELS:-self-hosted,cloud-run,linux}"

if [[ -z "$GITHUB_ORG" || -z "$APP_ID" || -z "$INSTALLATION_ID" ]]; then
  echo "[-] ERROR: GITHUB_ORG, GITHUB_APP_ID, and GITHUB_APP_INSTALLATION_ID must be set."
  exit 1
fi

if [[ ! -f "$PRIVATE_KEY_PATH" ]]; then
  echo "[-] ERROR: GitHub App private key not found at path: ${PRIVATE_KEY_PATH}"
  exit 1
fi

b64_url_encode() {
  openssl base64 -e -A | tr '+/' '-_' | tr -d '='
}

NOW=$(date +%s)
IAT=$((NOW - 60))
EXP=$((NOW + 540))

HEADER='{"alg":"RS256","typ":"JWT"}'
PAYLOAD=$(printf '{"iat":%d,"exp":%d,"iss":"%s"}' "$IAT" "$EXP" "$APP_ID")

HEADER_B64=$(echo -n "$HEADER" | b64_url_encode)
PAYLOAD_B64=$(echo -n "$PAYLOAD" | b64_url_encode)
UNSIGNED_JWT="${HEADER_B64}.${PAYLOAD_B64}"

SIGNATURE_B64=$(echo -n "$UNSIGNED_JWT" | openssl dgst -sha256 -sign "$PRIVATE_KEY_PATH" | b64_url_encode)
JWT="${UNSIGNED_JWT}.${SIGNATURE_B64}"

INSTALL_TOKEN_RES=$(curl -s -X POST \
  -H "Authorization: Bearer ${JWT}" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/app/installations/${INSTALLATION_ID}/access_tokens")

INSTALLATION_TOKEN=$(echo "$INSTALL_TOKEN_RES" | jq -r '.token // empty')
if [[ -z "$INSTALLATION_TOKEN" ]]; then
  echo "[-] ERROR: Failed to obtain installation access token."
  exit 1
fi

RUNNER_NAME="cloudrun-org-$(openssl rand -hex 3)"
LABELS_JSON=$(echo "$RUNNER_LABELS" | jq -R 'split(",")')

JIT_PAYLOAD=$(jq -n \
  --arg name "$RUNNER_NAME" \
  --arg group_id "$RUNNER_GROUP_ID" \
  --argjson labels "$LABELS_JSON" \
  '{
    name: $name,
    runner_group_id: ($group_id | tonumber),
    labels: $labels,
    work_folder: "_work"
  }')

JIT_RES=$(curl -s -X POST \
  -H "Authorization: Bearer ${INSTALLATION_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/orgs/${GITHUB_ORG}/actions/runners/generate-jitconfig" \
  -d "$JIT_PAYLOAD")

ENCODED_JIT_CONFIG=$(echo "$JIT_RES" | jq -r '.encoded_jit_config // empty')
if [[ -z "$ENCODED_JIT_CONFIG" ]]; then
  echo "[-] ERROR: Failed to generate JIT config."
  exit 1
fi

if [[ -d "/home/runner" ]]; then
  cd /home/runner
elif [[ -d "/actions-runner" ]]; then
  cd /actions-runner
fi

export ACTIONS_RUNNER_INPUT_JITCONFIG="${ENCODED_JIT_CONFIG}"
export RUNNER_ALLOW_RUNASROOT=1

trap 'exit 0' INT TERM

./run.sh &
RUNNER_PID=$!
wait "$RUNNER_PID"
