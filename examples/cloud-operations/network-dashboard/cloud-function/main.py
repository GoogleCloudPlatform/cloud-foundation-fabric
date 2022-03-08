#
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
#

from google.cloud import monitoring_v3
from googleapiclient import discovery
from google.api import metric_pb2 as ga_metric
import time
import os
import google.api_core
import re
import random

monitored_projects_list = os.environ.get("monitored_projects_list").split(",")  # list of projects from which function will get quotas information
monitoring_project_id = os.environ.get("monitoring_project_id")  # project where the metrics and dahsboards will be created
monitoring_project_link = f"projects/{monitoring_project_id}"
service = discovery.build('compute', 'v1')

# DEFAULT LIMITS
limit_vpc_peer = os.environ.get("LIMIT_VPC_PEER").split(",") # 25
limit_l4 = os.environ.get("LIMIT_L4").split(",") # 75
limit_l7 = os.environ.get("LIMIT_L7").split(",") # 75
limit_instances = os.environ.get("LIMIT_INSTANCES").split(",") # ["default_value", "15000"]
limit_instances_ppg = os.environ.get("LIMIT_INSTANCES_PPG").split(",")  # 15000
limit_subnets = os.environ.get("LIMIT_SUBNETS").split(",") # 400
limit_l4_ppg = os.environ.get("LIMIT_L4_PPG").split(",") # 175
limit_l7_ppg = os.environ.get("LIMIT_L7_PPG").split(",") # 175

# Cloud Function entry point
def quotas(request):
    global client, interval
    client, interval = create_client()

    # Instances per VPC
    instance_metric = create_gce_instances_metrics()
    get_gce_instances_data(instance_metric)

    # Number of VPC peerings per VPC
    vpc_peering_active_metric, vpc_peering_metric = create_vpc_peering_metrics()
    get_vpc_peering_data(vpc_peering_active_metric, vpc_peering_metric)

    # Internal L4 Forwarding Rules per VPC
    forwarding_rules_metric = create_l4_forwarding_rules_metric()
    get_l4_forwarding_rules_data(forwarding_rules_metric)

    # Internal L4 Forwarding Rules per VPC peering group
    # Existing GCP Monitoring metrics for L4 Forwarding Rules per Network
    l4_forwarding_rules_usage = "compute.googleapis.com/quota/internal_lb_forwarding_rules_per_vpc_network/usage"
    l4_forwarding_rules_limit = "compute.googleapis.com/quota/internal_lb_forwarding_rules_per_vpc_network/limit"

    l4_forwarding_rules_ppg_metric = create_l4_forwarding_rules_ppg_metric()
    get_pgg_data(l4_forwarding_rules_ppg_metric, l4_forwarding_rules_usage, l4_forwarding_rules_limit, limit_l4_ppg)

    # Internal L7 Forwarding Rules per VPC peering group
    # Existing GCP Monitoring metrics for L7 Forwarding Rules per Network
    l7_forwarding_rules_usage = "compute.googleapis.com/quota/internal_managed_forwarding_rules_per_vpc_network/usage"
    l7_forwarding_rules_limit = "compute.googleapis.com/quota/internal_managed_forwarding_rules_per_vpc_network/limit"

    l7_forwarding_rules_ppg_metric = create_l7_forwarding_rules_ppg_metric()
    get_pgg_data(l7_forwarding_rules_ppg_metric, l7_forwarding_rules_usage, l7_forwarding_rules_limit, limit_l7_ppg)

    # Subnet ranges per VPC peering group
    # Existing GCP Monitoring metrics for Subnet Ranges per Network
    subnet_ranges_usage = "compute.googleapis.com/quota/subnet_ranges_per_vpc_network/usage"
    subnet_ranges_limit = "compute.googleapis.com/quota/subnet_ranges_per_vpc_network/limit"

    subnet_ranges_ppg_metric = create_subnet_ranges_ppg_metric()
    get_pgg_data(subnet_ranges_ppg_metric, subnet_ranges_usage, subnet_ranges_limit, limit_subnets)

    # GCE Instances per VPC peering group
    # Existing GCP Monitoring metrics for GCE per Network
    gce_instances_usage = "compute.googleapis.com/quota/instances_per_vpc_network/usage"
    gce_instances_limit = "compute.googleapis.com/quota/instances_per_vpc_network/limit"

    gce_instances_metric = create_gce_instances_ppg_metric()
    get_pgg_data(gce_instances_metric, gce_instances_usage, gce_instances_limit, limit_instances_ppg)

    return 'Function executed successfully'

def create_client():
        try:
            client = monitoring_v3.MetricServiceClient()
            now = time.time()
            seconds = int(now)
            nanos = int((now - seconds) * 10 ** 9)
            interval = monitoring_v3.TimeInterval(
            {
                "end_time": {"seconds": seconds, "nanos": nanos},
                "start_time": {"seconds": (seconds - 86400), "nanos": nanos},
            })
            return (client, interval)
        except Exception as e:
            raise Exception("Error occurred creating the client: {}".format(e))

# Creates usage, limit and utilization Cloud monitoring metrics for GCE instances
# Returns a dictionary with the names and descriptions of the created metrics
def create_gce_instances_metrics():
    instance_metric = {}
    instance_metric["usage_name"] = "number_of_instances_usage"
    instance_metric["limit_name"] = "number_of_instances_limit"
    instance_metric["utilization_name"] = "number_of_instances_utilization"

    instance_metric["usage_description"] = "Number of instances per VPC network - usage."
    instance_metric["limit_description"] = "Number of instances per VPC network - effective limit."
    instance_metric["utilization_description"] = "Number of instances per VPC network - utilization."

    create_metric(instance_metric["usage_name"], instance_metric["usage_description"])
    create_metric(instance_metric["limit_name"], instance_metric["limit_description"])
    create_metric(instance_metric["utilization_name"], instance_metric["utilization_description"])

    return instance_metric

# Creates a Cloud Monitoring metric based on the parameter given if the metric is not already existing
def create_metric(metric_name, description):
    client = monitoring_v3.MetricServiceClient()

    metric_link = f"custom.googleapis.com/{metric_name}"
    types = []
    for desc in client.list_metric_descriptors(name=monitoring_project_link):
        types.append(desc.type)

    # If the metric doesn't exist yet, then we create it
    if metric_link not in types:
        descriptor = ga_metric.MetricDescriptor()
        descriptor.type = f"custom.googleapis.com/{metric_name}"
        descriptor.metric_kind = ga_metric.MetricDescriptor.MetricKind.GAUGE
        descriptor.value_type = ga_metric.MetricDescriptor.ValueType.DOUBLE
        descriptor.description = description
        descriptor = client.create_metric_descriptor(name=monitoring_project_link, metric_descriptor=descriptor)
        print("Created {}.".format(descriptor.name))

def get_gce_instances_data(instance_metric):
    
    # Existing GCP Monitoring metrics for GCE instances
    metric_instances_usage = "compute.googleapis.com/quota/instances_per_vpc_network/usage"
    metric_instances_limit = "compute.googleapis.com/quota/instances_per_vpc_network/limit"

    for project in monitored_projects_list:
        network_dict = get_networks(project)

        current_quota_usage = get_quota_current_usage(f"projects/{project}", metric_instances_usage)
        current_quota_limit = get_quota_current_limit(f"projects/{project}", metric_instances_limit)

        current_quota_usage_view = customize_quota_view(current_quota_usage)
        current_quota_limit_view = customize_quota_view(current_quota_limit)

        for net in network_dict:
            set_usage_limits(net, current_quota_usage_view, current_quota_limit_view, limit_instances)
            write_data_to_metric(project, net['usage'], instance_metric["usage_name"], net['network name'])
            write_data_to_metric(project, net['limit'], instance_metric["limit_name"], net['network name'])
            write_data_to_metric(project, net['usage']/ net['limit'], instance_metric["utilization_name"], net['network name'])

        print(f"Wrote number of instances to metric for projects/{project}")


# Creates 2 metrics: VPC peerings per VPC and active VPC peerings per VPC
def create_vpc_peering_metrics():
    vpc_peering_active_metric = {}
    vpc_peering_active_metric["usage_name"] = "number_of_active_vpc_peerings_usage"
    vpc_peering_active_metric["limit_name"] = "number_of_active_vpc_peerings_limit"
    vpc_peering_active_metric["utilization_name"] = "number_of_active_vpc_peerings_utilization"

    vpc_peering_active_metric["usage_description"] = "Number of active VPC Peerings per VPC - usage."
    vpc_peering_active_metric["limit_description"] = "Number of active VPC Peerings per VPC - effective limit."
    vpc_peering_active_metric["utilization_description"] = "Number of active VPC Peerings per VPC - utilization."

    vpc_peering_metric = {}
    vpc_peering_metric["usage_name"] = "number_of_vpc_peerings_usage"
    vpc_peering_metric["limit_name"] = "number_of_vpc_peerings_limit"
    vpc_peering_metric["utilization_name"] = "number_of_vpc_peerings_utilization"

    vpc_peering_metric["usage_description"] = "Number of VPC Peerings per VPC - usage."
    vpc_peering_metric["limit_description"] = "Number of VPC Peerings per VPC - effective limit."
    vpc_peering_metric["utilization_description"] = "Number of VPC Peerings per VPC - utilization."

    create_metric(vpc_peering_active_metric["usage_name"], vpc_peering_active_metric["usage_description"])
    create_metric(vpc_peering_active_metric["limit_name"], vpc_peering_active_metric["limit_description"])
    create_metric(vpc_peering_active_metric["utilization_name"], vpc_peering_active_metric["utilization_description"])

    create_metric(vpc_peering_metric["usage_name"], vpc_peering_metric["usage_description"])
    create_metric(vpc_peering_metric["limit_name"], vpc_peering_metric["limit_description"])
    create_metric(vpc_peering_metric["utilization_name"], vpc_peering_metric["utilization_description"])

    return vpc_peering_active_metric, vpc_peering_metric

# Populates data for VPC peerings per VPC and active VPC peerings per VPC
def get_vpc_peering_data(vpc_peering_active_metric, vpc_peering_metric):
    for project in monitored_projects_list:
        active_vpc_peerings, vpc_peerings = gather_vpc_peerings_data(project, limit_vpc_peer) 
        for peering in active_vpc_peerings:
            write_data_to_metric(project, peering['active_peerings'], vpc_peering_active_metric["usage_name"], peering['network name'])
            write_data_to_metric(project, peering['network_limit'], vpc_peering_active_metric["limit_name"], peering['network name'])
            write_data_to_metric(project, peering['active_peerings'] / peering['network_limit'], vpc_peering_active_metric["utilization_name"], peering['network name'])
        print("Wrote number of active VPC peerings to custom metric for project:", project)

        for peering in vpc_peerings:
            write_data_to_metric(project, peering['peerings'], vpc_peering_metric["usage_name"], peering['network name'])
            write_data_to_metric(project, peering['network_limit'], vpc_peering_metric["limit_name"], peering['network name'])
            write_data_to_metric(project, peering['peerings'] / peering['network_limit'], vpc_peering_metric["utilization_name"], peering['network name'])
        print("Wrote number of VPC peerings to custom metric for project:", project)

# gathers number of VPC peerings, active VPC peerings and limits, returns 2 dictionaries: active_vpc_peerings and vpc_peerings (including inactive and active ones)
def gather_vpc_peerings_data(project_id, limit_list):
    active_peerings_dict  = []
    peerings_dict = []
    request = service.networks().list(project=project_id)
    response = request.execute()
    if 'items' in response:
        for network in response['items']:
            if 'peerings' in network:
                STATE = network['peerings'][0]['state']
                if STATE == "ACTIVE":
                    active_peerings_count = len(network['peerings']) 
                else:
                    active_peerings_count = 0

                peerings_count = len(network['peerings']) 
            else:
                peerings_count = 0
                active_peerings_count = 0

            active_d = {'project_id': project_id,'network name':network['name'],'active_peerings':active_peerings_count,'network_limit': get_limit(network['name'], limit_list)}
            active_peerings_dict.append(active_d)
            d = {'project_id': project_id,'network name':network['name'],'peerings':peerings_count,'network_limit': get_limit(network['name'], limit_list)}
            peerings_dict.append(d)

    return active_peerings_dict, peerings_dict

# Check if the VPC has a specific limit for a specific metric, if so, returns that limit, if not, returns the default limit
def get_limit(network_name, limit_list):
    if network_name in limit_list:
        return int(limit_list[limit_list.index(network_name) + 1])
    else:
        if 'default_value' in limit_list:
            return int(limit_list[limit_list.index('default_value') + 1])
        else:
            return 0

# Creates the custom metrics for L4 internal forwarding Rules
def create_l4_forwarding_rules_metric():
    forwarding_rules_metric = {}
    forwarding_rules_metric["usage_name"] = "internal_forwarding_rules_l4_usage"
    forwarding_rules_metric["limit_name"] = "internal_forwarding_rules_l4_limit"
    forwarding_rules_metric["utilization_name"] = "internal_forwarding_rules_l4_utilization"

    forwarding_rules_metric["usage_description"] = "Number of Internal Forwarding Rules for Internal L4 Load Balancers - usage."
    forwarding_rules_metric["limit_description"] = "Number of Internal Forwarding Rules for Internal L4 Load Balancers - effective limit."
    forwarding_rules_metric["utilization_description"] = "Number of Internal Forwarding Rules for Internal L4 Load Balancers - utilization."

    create_metric(forwarding_rules_metric["usage_name"], forwarding_rules_metric["usage_description"])
    create_metric(forwarding_rules_metric["limit_name"], forwarding_rules_metric["limit_description"])
    create_metric(forwarding_rules_metric["utilization_name"], forwarding_rules_metric["utilization_description"])

    return forwarding_rules_metric

def get_l4_forwarding_rules_data(forwarding_rules_metric):

    # Existing GCP Monitoring metrics for L4 Forwarding Rules
    l4_forwarding_rules_usage = "compute.googleapis.com/quota/internal_lb_forwarding_rules_per_vpc_network/usage"
    l4_forwarding_rules_limit = "compute.googleapis.com/quota/internal_lb_forwarding_rules_per_vpc_network/limit"

    for project in monitored_projects_list:
        network_dict = get_networks(project)

        current_quota_usage = get_quota_current_usage(f"projects/{project}", l4_forwarding_rules_usage)
        current_quota_limit = get_quota_current_limit(f"projects/{project}", l4_forwarding_rules_limit)

        current_quota_usage_view = customize_quota_view(current_quota_usage)
        current_quota_limit_view = customize_quota_view(current_quota_limit)

        for net in network_dict:
            set_usage_limits(net, current_quota_usage_view, current_quota_limit_view, limit_l4)
            write_data_to_metric(project, net['usage'], forwarding_rules_metric["usage_name"], net['network name'])
            write_data_to_metric(project, net['limit'], forwarding_rules_metric["limit_name"], net['network name'])
            write_data_to_metric(project, net['usage']/ net['limit'], forwarding_rules_metric["utilization_name"], net['network name'])

        print(f"Wrote number of L4 forwarding rules to metric for projects/{project}")

# Creates the custom metrics for L4 internal forwarding Rules per VPC Peering Group
def create_l4_forwarding_rules_ppg_metric():
    forwarding_rules_metric = {}
    forwarding_rules_metric["usage_name"] = "internal_forwarding_rules_l4_ppg_usage"
    forwarding_rules_metric["limit_name"] = "internal_forwarding_rules_l4_ppg_limit"
    forwarding_rules_metric["utilization_name"] = "internal_forwarding_rules_l4_ppg_utilization"

    forwarding_rules_metric["usage_description"] = "Number of Internal Forwarding Rules for Internal l4 Load Balancers per peering group - usage."
    forwarding_rules_metric["limit_description"] = "Number of Internal Forwarding Rules for Internal l4 Load Balancers per peering group - effective limit."
    forwarding_rules_metric["utilization_description"] = "Number of Internal Forwarding Rules for Internal l4 Load Balancers per peering group - utilization."

    create_metric(forwarding_rules_metric["usage_name"], forwarding_rules_metric["usage_description"])
    create_metric(forwarding_rules_metric["limit_name"], forwarding_rules_metric["limit_description"])
    create_metric(forwarding_rules_metric["utilization_name"], forwarding_rules_metric["utilization_description"])

    return forwarding_rules_metric

# Creates the custom metrics for L7 internal forwarding Rules per VPC Peering Group
def create_l7_forwarding_rules_ppg_metric():
    forwarding_rules_metric = {}
    forwarding_rules_metric["usage_name"] = "internal_forwarding_rules_l7_ppg_usage"
    forwarding_rules_metric["limit_name"] = "internal_forwarding_rules_l7_ppg_limit"
    forwarding_rules_metric["utilization_name"] = "internal_forwarding_rules_l7_ppg_utilization"

    forwarding_rules_metric["usage_description"] = "Number of Internal Forwarding Rules for Internal l7 Load Balancers per peering group - usage."
    forwarding_rules_metric["limit_description"] = "Number of Internal Forwarding Rules for Internal l7 Load Balancers per peering group - effective limit."
    forwarding_rules_metric["utilization_description"] = "Number of Internal Forwarding Rules for Internal l7 Load Balancers per peering group - utilization."

    create_metric(forwarding_rules_metric["usage_name"], forwarding_rules_metric["usage_description"])
    create_metric(forwarding_rules_metric["limit_name"], forwarding_rules_metric["limit_description"])
    create_metric(forwarding_rules_metric["utilization_name"], forwarding_rules_metric["utilization_description"])

    return forwarding_rules_metric

def create_subnet_ranges_ppg_metric():
    metric = {}

    metric["usage_name"] = "number_of_subnet_IP_ranges_usage"
    metric["limit_name"] = "number_of_subnet_IP_ranges_effective_limit"
    metric["utilization_name"] = "number_of_subnet_IP_ranges_utilization"

    metric["usage_description"] = "Number of Subnet Ranges per peering group - usage."
    metric["limit_description"] = "Number of Subnet Ranges per peering group - effective limit."
    metric["utilization_description"] = "Number of Subnet Ranges per peering group - utilization."

    create_metric(metric["usage_name"], metric["usage_description"])
    create_metric(metric["limit_name"], metric["limit_description"])
    create_metric(metric["utilization_name"], metric["utilization_description"])

    return metric

def create_gce_instances_ppg_metric():
    metric = {}

    metric["usage_name"] = "number_of_instances_ppg_usage"
    metric["limit_name"] = "number_of_instances_ppg_limit"
    metric["utilization_name"] = "number_of_instances_ppg_utilization"

    metric["usage_description"] = "Number of instances per peering group - usage."
    metric["limit_description"] = "Number of instances per peering group - effective limit."
    metric["utilization_description"] = "Number of instances per peering group - utilization."

    create_metric(metric["usage_name"], metric["usage_description"])
    create_metric(metric["limit_name"], metric["limit_description"])
    create_metric(metric["utilization_name"], metric["utilization_description"])

    return metric

# Populates data for the custom metrics for L4 internal forwarding Rules per Peering Group
def get_pgg_data(forwarding_rules_ppg_metric, usage_metric, limit_metric, limit_ppg):

    for project in monitored_projects_list:
        network_dict_list = gather_peering_data(project)
        # Network dict list is a list of dictionary (one for each network)
        # For each network, this dictionary contains:
        #   project_id, network_name, network_id, usage, limit, peerings (list of peered networks)
        #   peerings is a list of dictionary (one for each peered network) and contains:
        #       project_id, network_name, network_id
        
        # For each network in this GCP project
        for network_dict in network_dict_list:
            current_quota_usage = get_quota_current_usage(f"projects/{project}", usage_metric)
            current_quota_limit = get_quota_current_limit(f"projects/{project}", limit_metric)

            current_quota_usage_view = customize_quota_view(current_quota_usage)
            current_quota_limit_view = customize_quota_view(current_quota_limit)

            usage, limit = get_usage_limit(network_dict, current_quota_usage_view, current_quota_limit_view, limit_ppg)
            # Here we add usage and limit to the network dictionary
            network_dict["usage"] = usage
            network_dict["limit"] = limit

            # For every peered network, get usage and limits
            for peered_network in network_dict['peerings']:
                peering_project_usage = customize_quota_view(get_quota_current_usage(f"projects/{peered_network['project_id']}", usage_metric))
                peering_project_limit = customize_quota_view(get_quota_current_limit(f"projects/{peered_network['project_id']}", limit_metric))

                usage, limit = get_usage_limit(peered_network, peering_project_usage, peering_project_limit, limit_ppg)
                # Here we add usage and limit to the peered network dictionary
                peered_network["usage"] = usage
                peered_network["limit"] = limit

            count_effective_limit(project, network_dict, forwarding_rules_ppg_metric["usage_name"], forwarding_rules_ppg_metric["limit_name"], forwarding_rules_ppg_metric["utilization_name"], limit_ppg)
            print(f"Wrote {forwarding_rules_ppg_metric['usage_name']} to metric for peering group {network_dict['network_name']} in {project}")

# Calculates the effective limits (using algorithm in the link below) for peering groups and writes data (usage, limit, utilization) to metric
# https://cloud.google.com/vpc/docs/quota#vpc-peering-effective-limit
def count_effective_limit(project_id, network_dict, usage_metric_name, limit_metric_name, utilization_metric_name, limit_ppg):

    if network_dict['peerings'] == []:
        return

    # Get usage: Sums usage for current network + all peered networks
    peering_group_usage = network_dict['usage']
    for peered_network in network_dict['peerings']:
        peering_group_usage += peered_network['usage']

    # Calculates effective limit: Step 1: max(per network limit, per network_peering_group limit)
    limit_step1 = max(network_dict['limit'], get_limit(network_dict['network_name'], limit_ppg))

    # Calculates effective limit: Step 2: List of max(per network limit, per network_peering_group limit) for each peered network
    limit_step2 = []
    for peered_network in network_dict['peerings']:
        limit_step2.append(max(peered_network['limit'], get_limit(peered_network['network_name'], limit_ppg)))

    # Calculates effective limit: Step 3: Find minimum from the list created by Step 2
    limit_step3 = min(limit_step2)

    # Calculates effective limit: Step 4: Find maximum from step 1 and step 3
    effective_limit = max(limit_step1, limit_step3)
    utilization = peering_group_usage / effective_limit

    write_data_to_metric(project_id, peering_group_usage, usage_metric_name, network_dict['network_name'])
    write_data_to_metric(project_id, effective_limit, limit_metric_name, network_dict['network_name'])
    write_data_to_metric(project_id, utilization, utilization_metric_name, network_dict['network_name'])

# Takes a project id as argument (and service for the GCP API call) and return a dictionary with the list of networks
def get_networks(project_id):
    request = service.networks().list(project=project_id)
    response = request.execute()
    network_dict = []
    if 'items' in response:
        for network in response['items']:
            NETWORK = network['name']
            ID = network['id']
            d = {'project_id':project_id,'network name':NETWORK,'network id':ID}
            network_dict.append(d)
    return network_dict

# gathers data for peered networks for the given project_id
def gather_peering_data(project_id):
    request = service.networks().list(project=project_id)
    response = request.execute()

    # list of networks in that project
    network_list = []
    if 'items' in response:
        for network in response['items']:
            net = {'project_id':project_id,'network_name':network['name'],'network_id':network['id'], 'peerings':[]}
            if 'peerings' in network:
                STATE = network['peerings'][0]['state']
                if STATE == "ACTIVE":
                    for peered_network in network['peerings']:  # "projects/{project_name}/global/networks/{network_name}"
                        start = peered_network['network'].find("projects/") + len('projects/')
                        end = peered_network['network'].find("/global")
                        peered_project = peered_network['network'][start:end]
                        peered_network_name  = peered_network['network'].split("networks/")[1]
                        peered_net = {'project_id': peered_project, 'network_name':peered_network_name, 'network_id': get_network_id(peered_project, peered_network_name)}
                        net["peerings"].append(peered_net)
            network_list.append(net)
    return network_list

def get_network_id(project_id, network_name):
    request = service.networks().list(project=project_id)
    response = request.execute()

    network_id = 0

    if 'items' in response:
        for network in response['items']:
            if network['name'] == network_name:
                network_id = network['id']
                break
    
    if network_id == 0:
        print(f"Error: network_id not found for {network_name} in {project_id}")
    
    return network_id

# retrieves quota for "type" in project_link, otherwise returns null (assume 0 for building comparison vs limits)
def get_quota_current_usage(project_link, type):
    results = client.list_time_series(request={
        "name": project_link,
        "filter": f'metric.type = "{type}"',
        "interval": interval,
        "view": monitoring_v3.ListTimeSeriesRequest.TimeSeriesView.FULL
    })
    results_list = list(results)
    return (results_list)

# retrieves quota for services limits
def get_quota_current_limit(project_link, type):
    results = client.list_time_series(request={
        "name": project_link,
        "filter": f'metric.type = "{type}"',
        "interval": interval,
        "view": monitoring_v3.ListTimeSeriesRequest.TimeSeriesView.FULL
    })
    results_list = list(results)
    return (results_list)

# Customize the quota output
def customize_quota_view(quota_results):
    quotaViewList = []
    for result in quota_results:
        quotaViewJson = {}
        quotaViewJson.update(dict(result.resource.labels))
        quotaViewJson.update(dict(result.metric.labels))
        for val in result.points:
            quotaViewJson.update({'value': val.value.int64_value})
        quotaViewList.append(quotaViewJson)
    return (quotaViewList)

# Takes a network dictionary and updates it with the quota usage and limits values
def set_usage_limits(network, quota_usage, quota_limit, limit_list):
    if quota_usage:
        for net in quota_usage: 
            if net['network_id'] == network['network id']:  # if network ids in GCP quotas and in dictionary (using API) are the same
                network['usage'] = net['value']  # set network usage in dictionary 
                break
            else:
                network['usage'] = 0  # if network does not appear in GCP quotas
    else:
        network['usage'] = 0  # if quotas does not appear in GCP quotas

    if quota_limit:
        for net in quota_limit:
            if net['network_id'] == network['network id']:  # if network ids in GCP quotas and in dictionary (using API) are the same
                network['limit'] = net['value']  # set network limit in dictionary 
                break
            else:
                if network['network name'] in limit_list:  # if network limit is in the environmental variables
                    network['limit'] = int(limit_list[limit_list.index(network['network name']) + 1]) 
                else:
                    network['limit'] = int(limit_list[limit_list.index('default_value') + 1])  # set default value
    else:  # if quotas does not appear in GCP quotas
        if network['network name'] in limit_list:
            network['limit'] = int(limit_list[limit_list.index(network['network name']) + 1])  # ["default", 100, "networkname", 200]
        else:
            network['limit'] =  int(limit_list[limit_list.index('default_value') + 1])

# Takes a network dictionary (with at least network_id and network_name) and returns usage and limit for that network
def get_usage_limit(network, quota_usage, quota_limit, limit_list):
    usage = 0
    limit = 0

    if quota_usage:
        for net in quota_usage: 
            if net['network_id'] == network['network_id']:  # if network ids in GCP quotas and in dictionary (using API) are the same
                usage = net['value']  # set network usage in dictionary 
                break

    if quota_limit:
        for net in quota_limit:
            if net['network_id'] == network['network_id']:  # if network ids in GCP quotas and in dictionary (using API) are the same
                limit = net['value']  # set network limit in dictionary 
                break
            else:
                if network['network_name'] in limit_list:  # if network limit is in the environmental variables
                    limit = int(limit_list[limit_list.index(network['network_name']) + 1]) 
                else:
                    limit = int(limit_list[limit_list.index('default_value') + 1])  # set default value
    else:  # if quotas does not appear in GCP quotas
        if network['network_name'] in limit_list:
            limit = int(limit_list[limit_list.index(network['network_name']) + 1])  # ["default", 100, "networkname", 200]
        else:
            limit =  int(limit_list[limit_list.index('default_value') + 1])

    return usage, limit

# Writes data to Cloud Monitoring data
# Note that the monitoring_project_id here should be the monitoring project where the metrics are written
# and monitored_project_id is the monitored project, containing the network and resources
def write_data_to_metric(monitored_project_id, value, metric_name, network_name):
    series = monitoring_v3.TimeSeries()
    series.metric.type = f"custom.googleapis.com/{metric_name}"
    series.resource.type = "global" 
    series.metric.labels["network_name"] = network_name
    series.metric.labels["project"] = monitored_project_id

    now = time.time()
    seconds = int(now)
    nanos = int((now - seconds) * 10 ** 9)
    interval = monitoring_v3.TimeInterval({"end_time": {"seconds": seconds, "nanos": nanos}})
    point = monitoring_v3.Point({"interval": interval, "value": {"double_value": value}})
    series.points = [point]

    client.create_time_series(name=monitoring_project_link, time_series=[series])