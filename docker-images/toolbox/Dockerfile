# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM debian:buster-slim

ENV DEBIAN_FRONTEND noninteractive

COPY entrypoint.sh /entrypoint.sh
RUN chmod 0755 /entrypoint.sh

RUN apt-get update && apt-get install -y -qq --no-install-recommends wget curl unzip python openssh-client python-openssl ca-certificates && apt-get clean

# Various networking and other tools. net-tools installs arp, netstat, etc.
RUN apt-get install -u -qq vim \
    net-tools netcat ipset conntrack inetutils-traceroute bridge-utils \
    ebtables dnsutils iputils-ping mtr telnet \
    && apt-get clean

# COPY cos-kernel /usr/local/bin
RUN wget -O /usr/local/bin/cos-kernel https://raw.githubusercontent.com/GoogleCloudPlatform/cos-toolbox/master/cos-kernel

RUN mkdir /.ssh
VOLUME ["/.config"]

CMD ["/bin/bash"]

ENTRYPOINT ["/entrypoint.sh"]
