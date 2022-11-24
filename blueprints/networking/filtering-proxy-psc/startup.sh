# Copyright 2022 Google LLC
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

cat <<EOF > /etc/apt/apt.conf.d/proxy.conf
Acquire {
  HTTP::proxy "${proxy_url}";
  HTTPS::proxy "${proxy_url}";
}
EOF

cat <<EOF > /etc/profile.d/proxy.sh
export http_proxy="${proxy_url}"
export https_proxy="${proxy_url}"
export no_proxy="127.0.0.1,localhost"
EOF
