#
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

FROM google/cloud-sdk:slim

# Add MongoDB clients etc.
RUN curl -sL https://www.mongodb.org/static/pgp/server-6.0.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/mongodb.gpg
RUN echo "deb http://repo.mongodb.org/apt/debian bullseye/mongodb-org/6.0 main" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list && apt-get update
RUN apt-get install -y mongodb-mongosh jq vim
RUN apt-get dist-upgrade -y

RUN mkdir -p /scripts
WORKDIR /scripts

ADD startup.sh .
ADD shutdown.sh .

ENTRYPOINT [ "/bin/bash" ]