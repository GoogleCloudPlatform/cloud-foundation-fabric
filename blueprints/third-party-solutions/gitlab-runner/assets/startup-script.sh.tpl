#!/bin/bash
# Copyright 2024 Google LLC
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

GITLAB_URL=https://${gitlab_hostname}
GITLAB_RUNNER_CONFIG=${gitlab_runner_config}
GITLAB_TOKEN_SECRET_ID=${gitlab_token_secret_id}
GITLAB_TOKEN_SECRET_VERSION="latest"
GL_NAME=$(curl 169.254.169.254/computeMetadata/v1/instance/name --header "Metadata-Flavor:Google")
GL_EXECUTOR=$(curl 169.254.169.254/computeMetadata/v1/instance/attributes/gl_executor --header "Metadata-Flavor:Google")

apt update
curl --location "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | bash

# Fetch Gitlab Server SSL Private and public keys
echo "${gitlab_ca_cert}" | base64 -d -w0 >/tmp/ca.crt
cp -f /tmp/ca.crt /usr/local/share/ca-certificates/
update-ca-certificates

# Install Docker
# Add Docker's official GPG key:
apt-get update
apt-get install -yq ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository to Apt sources:
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list >/dev/null
apt-get update
apt-get install -yq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Install Gitlab Runner
apt install -y gitlab-runner

# setup new gitlab runner config
echo $GITLAB_RUNNER_CONFIG | base64 -d > /etc/gitlab-runner/config.toml

%{ if gitlab_executor_type == "docker-autoscaler" }
# Install GCP fleeting plugin for Docker Autoscale Runner
# https://docs.gitlab.com/runner/executors/docker_autoscaler.html#install-a-fleeting-plugin
wget https://gitlab.com/gitlab-org/fleeting/fleeting-plugin-googlecompute/-/releases/v0.1.0/downloads/fleeting-plugin-googlecompute-linux-386
chmod +x fleeting-plugin-googlecompute-linux-386
mv ./fleeting-plugin-googlecompute-linux-386 /usr/bin/fleeting-plugin-googlecompute
%{ endif }

# Fetch the gitlab auth token value from secret manager
TOKEN=$(gcloud secrets versions access $GITLAB_TOKEN_SECRET_VERSION --secret $GITLAB_TOKEN_SECRET_ID)

gitlab-runner register --non-interactive --name="$GL_NAME" \
  --url="$GITLAB_URL" --token="$TOKEN" --template-config="/etc/gitlab-runner/config.toml" \
  --executor="${gitlab_executor_type}"
systemctl restart gitlab-runner
