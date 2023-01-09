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

export HOME=/tmp
MONGOSH_CONNECTION=""

log_message() {
    echo "[MongoDB cluster:startup] $@" >&2
}

get_metadata_value () {
  local key="$1"
  
  curl -sH 'Metadata-Flavor: Google' "http://metadata.google.internal/computeMetadata/v1/$key"
}

run_mongosh_command () {
    mongosh --eval "JSON.stringify($@)" ${MONGOSH_ARGS[@]} ${MONGOSH_CONNECTION} --quiet 2>&1
}

wait_mongodb_available () {
    while true
    do
        log_message "Waiting for MongoDB to become available..."
        status=$(run_mongosh_command 'db.runCommand({ ping: 1 })' | jq -r '.ok')
        if [ "$status" == "1" ] ; then
            log_message "MongoDB is now available."
            break
        fi
        sleep 2
    done
}

wait_replica_set_available () {
    while true
    do
        log_message "Waiting for MongoDB replica set configuration to become available..."
        replica_set_status=$(run_mongosh_command 'rs.status()')
        if [[ "$replica_set_status" != *"no replset config"* ]]; then
            log_message "Replica set is now configured."
            break
        fi
        sleep 2
    done
}

switch_to_local_connection() {
    MONGOSH_CONNECTION="mongodb://localhost/?connectTimeoutMS=1000&socketTimeoutMS=1000"
    log_message "Using connection: ${MONGOSH_CONNECTION}"
}

switch_to_replica_set_connection () {
    replset_hosts_str=$(echo "$@" | sed 's/ /,/g')
    MONGOSH_CONNECTION="mongodb://${replset_hosts_str}/?replicaSet=${REPLSET}&connectTimeoutMS=10000&socketTimeoutMS=10000"
    log_message "Using connection: ${MONGOSH_CONNECTION}"
}

switch_to_replica_set_connection_no_local () {
    hosts=$@
    for i in "${!array[@]}"; do
        if [[ ${array[i]} = $target ]]; then
            unset 'array[i]'
        fi
    done

    replset_hosts_str=$(echo "$@" | sed 's/ /,/g')
    MONGOSH_CONNECTION="mongodb://${replset_hosts_str}/?replicaSet=${REPLSET}&connectTimeoutMS=10000&socketTimeoutMS=10000"
    log_message "Using connection: ${MONGOSH_CONNECTION}"
}

am_i_the_primary () {
    replica_primary=$(run_mongosh_command "rs.status().members.find(function (elem) { if (elem.stateStr == 'PRIMARY') { return elem; } })" | jq -r '.name' | sed 's/:.*//')
    if [ "${INSTANCE_HOSTNAME}" == "${replica_primary}" ] ; then
        return 0
    fi
    return 1
}

INSTANCE_NAME=$(get_metadata_value "instance/name")
ZONE=$(get_metadata_value "instance/zone")
INSTANCE_GROUP=$(gcloud compute instances describe \
    ${INSTANCE_NAME} --zone=${ZONE} \
    --format='value(metadata.items.filter("key:created-by").firstof("value"))')
INSTANCE_GROUP_BASENAME=$(echo ${INSTANCE_GROUP} | sed 's/^.*\///')
INSTANCE_HOSTNAME=$(get_metadata_value "instance/hostname")
DOMAIN=$(echo $INSTANCE_HOSTNAME | sed 's/^[^\.]*//' | sed 's/^\.[^\.]*//')
log_message "Instance name: ${INSTANCE_NAME} (internal DNS domain: ${DOMAIN})"
log_message "Instance zone: ${ZONE}"
log_message "Instance group: ${INSTANCE_GROUP}"
log_message "Replica set: ${REPLSET}"

log_message "Waiting for the instance group to be stable..."
gcloud compute instance-groups managed wait-until ${INSTANCE_GROUP} --stable
log_message "Instance group is now stable."

FIRST_INSTANCE=$(gcloud compute instance-groups managed \
    list-instances ${INSTANCE_GROUP} --format='value(instance.basename())' \
    --sort-by='name' | head -n 1)

if [ -n "${MONGO_INITDB_ROOT_USERNAME}" ] && [ -n "${MONGO_INITDB_ROOT_PASSWORD}" ] ; then
    MONGOSH_ARGS="${MONGOSH_ARGS} -u \"${MONGO_INITDB_ROOT_USERNAME}\" -p \"${MONGO_INITDB_ROOT_PASSWORD}\""
fi

switch_to_local_connection

wait_mongodb_available

declare -a replset_hosts=()
while read -r -a instance 
do
    replset_hosts+=( "${instance[0]}.${instance[1]}${DOMAIN}:${MONGO_PORT}" )
done < <( gcloud compute instance-groups managed list-instances ${INSTANCE_GROUP} --format='value[separator=" "](instance, instance.always().segment(-3))' --sort-by='name' )

if [ "${INSTANCE_NAME}" == "${FIRST_INSTANCE}" ] ; then
    log_message "I'm the first instance, checking for existing replica set..."
    replica_set_status=$(run_mongosh_command 'rs.status()')
    if [[ "$replica_set_status" == *"no replset config"* ]]; then
        log_message "Replica set not configured, building list of replicas."
        declare -a replica_hosts=()
        replica_config="rs.initiate({_id : \"${REPLSET}\", members: ["
        index=0
        while read -r -a instance 
        do
            replica_hosts+=( "{ _id: $index, host: \"${instance[0]}.${instance[1]}${DOMAIN}:${MONGO_PORT}\" }" )
            index=$(($index+1))
        done < <( gcloud compute instance-groups managed list-instances ${INSTANCE_GROUP} --format='value[separator=" "](instance, instance.always().segment(-3))' --sort-by='name' )
        replica_hosts_str=$(IFS=, ; echo "${replica_hosts[*]}")
        replica_config="${replica_config}${replica_hosts_str}]})"
        run_mongosh_command "rs.initiate(${replica_config})"
        log_message "Replica set was initiated with configuration: ${replica_config}"
    else
        log_message "Replica set has been configured already:"
        log_message "${replica_set_status}"

        switch_to_replica_set_connection "${replset_hosts[@]}"
        run_mongosh_command 'rs.status()'
    fi
else
    log_message "I'm not the first instance, checking if I am a member of the replica set..."

    switch_to_replica_set_connection "${replset_hosts[@]}"
    wait_replica_set_available

    replica_member=$(run_mongosh_command "rs.status().members.find(function (elem) { if (elem.name.indexOf(\"${INSTANCE_HOSTNAME}\") > -1) { return elem; } })")
    if [ -z "${replica_member}" ] ; then
        log_message "I am not a member of the replica set, adding myself to the replica set."
        add_to_replicaset=$(run_mongosh_command "rs.add({ host: \"${INSTANCE_HOSTNAME}:${MONGO_PORT}\" })")
        log_message "This instance added as replica set member: ${add_to_replicaset}"
    else
        log_message "I am a member of the replica set: ${replica_member}"
    fi
fi


log_message "Startup complete."
switch_to_replica_set_connection "${replset_hosts[@]}"

DNS_DOMAIN=
DNS_RECORD=
if [ -n "${DNS_ZONE}" ] ; then
    log_message "Setting up DNS."

    DNS_DOMAIN=$(gcloud dns managed-zones describe ${DNS_ZONE} --format='value(dnsName)')
    DNS_RECORD="_mongodb._tcp.${DNS_DOMAIN}"
    CONFIG_DNS_RECORD="${DNS_DOMAIN}"
    MY_DNS_RECORD="${INSTANCE_NAME}.${DNS_DOMAIN}"
    if am_i_the_primary ; then
        log_message "Creating a DNS SRV record: ${DNS_RECORD}"
        gcloud --quiet dns record-sets create ${DNS_RECORD} --rrdatas "0 0 27107 localhost." --type=SRV --ttl=30 --zone=${DNS_ZONE}
        
        log_message "Creating a DNS TXT record: ${CONFIG_DNS_RECORD}"
        if ! gcloud --quiet dns record-sets create ${CONFIG_DNS_RECORD} --rrdatas "replicaSet=${REPLSET}&ssl=false" --type=TXT --ttl=600 --zone=${DNS_ZONE} ; then
            gcloud --quiet dns record-sets update ${CONFIG_DNS_RECORD} --rrdatas "replicaSet=${REPLSET}&ssl=false" --type=TXT --ttl=600 --zone=${DNS_ZONE}
        fi
    fi

    log_message "Creating a DNS CNAME record: ${MY_DNS_RECORD}"
    if ! gcloud --quiet dns record-sets create ${MY_DNS_RECORD} --rrdatas "${INSTANCE_HOSTNAME}." --type=CNAME --ttl=600 --zone=${DNS_ZONE} ; then
        gcloud --quiet dns record-sets update ${MY_DNS_RECORD} --rrdatas "${INSTANCE_HOSTNAME}." --type=CNAME --ttl=600 --zone=${DNS_ZONE}
    fi
fi

while true
do  
    if [ -n "${DNS_ZONE}" ] ; then
        if am_i_the_primary ; then
            declare -a replica_members=()
            while read -r -a member
            do
                member_hostname=$(echo ${member} | sed 's/:.*//' | sed 's/\..*//')
                member_port=$(echo ${member} | sed 's/.*://')
                replica_members+=("0 0 ${member_port} ${member_hostname}.${INSTANCE_GROUP_BASENAME}.${DNS_DOMAIN}")
            done < <( run_mongosh_command "rs.status().members.filter(function (elem) { if (elem.health == 1) { return elem; } })" | jq -r '.[] | .name')

            if [ ${#replica_members[@]} -gt 0 ] ; then
                rrdatas=$(IFS=, ; echo "${replica_members[*]}")
                log_message "Updating DNS SRV record ${DNS_RECORD}: ${rrdatas}"
                gcloud dns record-sets --quiet --verbosity=error update ${DNS_RECORD} --rrdatas "${rrdatas}" --type=SRV --ttl=30 --zone=${DNS_ZONE} >/dev/null
            else
                log_message "Warning: No replica members detected, skipping DNS update."
            fi
        fi
    fi
    sleep 60
done