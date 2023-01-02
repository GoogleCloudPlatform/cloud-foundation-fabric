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
 
#!/bin/bash

if [ $# -lt 2 ]; then
    echo "Usage: $0 ENVGROUP_HOSTNAME NUM_REQUESTS"
    exit 1
fi    

ENVGROUP_HOSTNAME=$1
NUM_REQUESTS=$2

for i in $(seq 1 $NUM_REQUESTS)
do
curl -v https://$ENVGROUP_HOSTNAME/httpbin/headers
done
