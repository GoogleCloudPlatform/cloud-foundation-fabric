# Copyright 2023 Google LLC
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

#!/bin/bash

GITLAB_URL=https://${gitlab_hostname}
GITLAB_RUNNER_CONFIG=${gitlab_runner_config}

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

# setup new gitlab runner config
echo $GITLAB_RUNNER_CONFIG | base64 -d > /etc/gitlab-runner/config.toml

# Install Gitlab Runner
apt install -y gitlab-runner
gitlab-runner register --non-interactive --name="$GL_NAME" \
  --url="$GITLAB_URL" --token="${token}" --template-config="/etc/gitlab-runner/config.toml"
  --request-concurrency="12" --executor="docker" \
  --docker-image="alpine:latest"
systemctl restart gitlab-runner
