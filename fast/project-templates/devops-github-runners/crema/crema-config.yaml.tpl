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

apiVersion: crema/v1
kind: CremaConfig
metadata:
  name: github-runner-autoscaler
spec:
  pollingInterval: ${polling_interval}
  scaledObjects:
    - spec:
        scaleTargetRef:
          name: projects/${project_id}/locations/${region}/workerPools/${worker_pool_name}
        minReplicaCount: ${min_replicas}
        maxReplicaCount: ${max_replicas}
        advanced:
          horizontalPodAutoscalerConfig:
            behavior:
              scaleDown:
                stabilizationWindowSeconds: ${cooldown_period}
                policies:
                  - type: Percent
                    value: 100
                    periodSeconds: 15
        triggers:
          - type: github-runner
            metadata:
              owner: "${github_org}"
              runnerScope: "org"
              applicationID: "${github_app_id}"
              installationID: "${github_app_installation_id}"
              targetWorkflowQueueLength: "${target_workflow_queue_length}"
              labels: "${runner_labels}"
            authenticationRef:
              name: github-app-auth
  triggerAuthentications:
    - metadata:
        name: github-app-auth
      spec:
        gcpSecretManager:
          secrets:
            - parameter: appKey
              id: ${github_app_private_key_secret_name}
              version: latest
