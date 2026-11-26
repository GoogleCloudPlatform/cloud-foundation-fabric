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

FROM ghcr.io/actions/actions-runner:latest

USER root

ENV RUNNER_ALLOW_RUNASROOT=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    jq \
    openssl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN echo "root ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/root \
    && chmod 0440 /etc/sudoers.d/root

COPY start.sh /home/runner/start.sh
RUN chmod 755 /home/runner/start.sh

WORKDIR /home/runner
ENTRYPOINT ["/home/runner/start.sh"]
