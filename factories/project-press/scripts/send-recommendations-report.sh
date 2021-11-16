#!/bin/bash
# Copyright 2021 Google LLC
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

JOBDATA=$(gcloud scheduler jobs describe $1 --format='json(pubsubTarget.topicName,pubsubTarget.data)')

TOPIC=$(echo $JOBDATA | python3 -c 'import sys;import json;d=json.loads(sys.stdin.read());print(d["pubsubTarget"]["topicName"])')
MESSAGE=$(echo $JOBDATA | python3 -c 'import base64;import sys;import json;d=json.loads(sys.stdin.read());m=json.loads(base64.b64decode(d["pubsubTarget"]["data"]));m["send_now"]=True;print(json.dumps(m))')

echo "Publish message to $TOPIC: $MESSAGE"
gcloud pubsub topics publish $TOPIC --message="$MESSAGE"