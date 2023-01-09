#!/bin/bash
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

MONGO_PORT=27017
while getopts r:p:z: flag
do
    case "${flag}" in
        r) REPLSET=${OPTARG};;
        p) MONGO_PORT=${OPTARG};;
        z) DNS_ZONE=${OPTARG};;
    esac
done

log_message() {
    echo "[MongoDB cluster:shutdown] $@" >&2
}

get_metadata_value () {
  local key="$1"
  
  curl -sH 'Metadata-Flavor: Google' "http://metadata.google.internal/computeMetadata/v1/$key"
}

log_message "Shutdown sequence started."

INSTANCE_NAME=$(get_metadata_value "instance/name")
ZONE=$(get_metadata_value "instance/zone")
INSTANCE_GROUP=$(gcloud compute instances describe \
    ${INSTANCE_NAME} --zone=${ZONE} \
    --format='value(metadata.items.filter("key:created-by").firstof("value"))')
INSTANCE_GROUP_BASENAME=$(echo ${INSTANCE_GROUP} | sed 's/^.*\///')
INSTANCE_HOSTNAME=$(get_metadata_value "instance/hostname")
DOMAIN=$(echo $INSTANCE_HOSTNAME | sed 's/^[^\.]*//' | sed 's/^\.[^\.]*//')

log_message "Getting instance group status..."
DELETING_INSTANCES=$(gcloud compute instance-groups managed describe ${INSTANCE_GROUP} --format='value(currentActions.deleting)')
if [ ${DELETING_INSTANCES} -gt 0 ] ; then
    log_message "Instance group is being deleted."
    if [ -n "${DNS_ZONE}" ] ; then
        DNS_DOMAIN=$(gcloud dns managed-zones describe ${DNS_ZONE} --format='value(dnsName)')
        MY_DNS_RECORD="${INSTANCE_NAME}.${DNS_DOMAIN}"
        log_message "Deleting this instance's CNAME record: ${MY_DNS_RECORD}"
        gcloud --quiet dns record-sets delete ${MY_DNS_RECORD} --type=CNAME --zone=${DNS_ZONE}
    fi
fi

log_message "Shutdown actions finished."
sleep 5