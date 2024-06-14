#!/usr/bin/env bash
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

# BindPlane Agent with Terraform
# https://github.com/GoogleCloudPlatform/monitoring-dashboard-samples/tree/master/terraform/agents/bindplane

# Install prerequisites
sudo apt-get install -y rsync

# Setting up Cloud Monitoring with a standalone agent
# https://cloud.google.com/vmware-engine/docs/environment/howto-cloud-monitoring-standalone
curl -s ${endpoint_agent} -o /tmp/agent.tar.gz
curl -s ${endpoint_install} -o /tmp/install.sh
sudo chmod +x /tmp/install.sh
sudo /tmp/install.sh /tmp/agent.tar.gz

# Configure the agent to access your private cloud for metrics
sudo cp /opt/bpagent/config/metrics/examples/vmware_vcenter.yaml /opt/bpagent/config/metrics/sources
gcloud config set project ${project_id}
sudo sed -i "s/host:.*$/host: $(${gcloud_secret_vsphere_server})/g" /opt/bpagent/config/metrics/sources/vmware_vcenter.yaml
sudo sed -i "s/username:.*$/username: $(${gcloud_secret_vsphere_user})/g" /opt/bpagent/config/metrics/sources/vmware_vcenter.yaml
sudo sed -i "s/password:.*$/password: $(${gcloud_secret_vsphere_password})/g" /opt/bpagent/config/metrics/sources/vmware_vcenter.yaml
sudo sed -i "s/# region:.*$/region: ${gcve_region}/g" /opt/bpagent/config/metrics/sources/vmware_vcenter.yaml

#Configure the agent to access the service account for reporting
sudo cp /opt/bpagent/config/log_agent.example.yaml /opt/bpagent/config/log_agent.yaml
sudo sed -i "s/project_id:.*$/project_id: ${project_id}/g" /opt/bpagent/config/log_agent.yaml
sudo sed -i "s/credentials_file:.*$/#credentials_file: /g" /opt/bpagent/config/log_agent.yaml

sudo systemctl stop bpagent
sudo systemctl start bpagent
sudo systemctl enable bpagent