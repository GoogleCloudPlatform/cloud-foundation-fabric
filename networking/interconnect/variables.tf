/**
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


variable "router_name" {
    description = "Router name. Leave blank to use Vlan attahcement name"
    type=string   
    default=""
}

variable "router_description" {
    description = "An optional router description "
    type=string  
    default="" 
}


variable "encrypted_interconnect_router"{
  description ="Field to indicate if a router is dedicated to use with encrypted Interconnect Attachment.Not yet available to the public "
  type = bool
  default="false"
}


variable "region"{
  description="Region where the router resides"
  type=string
  default="us-west2"
}

variable "project_id"{
  description="The project containing the resources"
  type=string
}

variable "router_advertise_config" {
  description = "Router custom advertisement configuration, ip_ranges is a map of address ranges and descriptions."
  type = object({
    groups    = list(string)
    ip_ranges = map(string)
    mode      = string
    
  })
  default = null
}

variable "asn"{
  description="Local BGP Autonomous System Number (ASN)"
  type=number
}



variable "network_name" {
    description = "A reference to the network to which this router belongs"
    type=string   
}





variable "vlan_attachment_name"{
  description = "Vlan attachment name"
  type=string
}

variable "interconnect"{
  description="Interconnect name "
  type=string
}
variable "description"{
  description="Vlan attachement description"
  type=string
  default=""
}



variable "interconnect_region"{
  description="The region where the interconnect resides"
  type=string
  default="us-west2"
}

variable "vlan_id"{
  description="VLAN tag for this attachment"
  type=number
  default=0
}




variable "bandwidth"{
  description="Provisioned bandwidth capacity for the interconnect attachment"
  type=string
  default="BPS_10G"

}

variable "bgp_session_name"{
  description="Bgp session name"
  type=string
}

variable "peer_asn"{
  description="Peer BGP Autonomous System Number (ASN)."
  type=number
}

variable "peer_ip_address"{
  description="IP address of the BGP interface"
  type=string
}

variable "candidate_ip_ranges"{
  description="User-specified list of individual IP ranges to advertise in custom mode. "
  type=list(string)
  default={}
}




variable "advertised_route_priority"{
  description="The priority of routes advertised to this BGP peer. "
  type=number
  default=0
}


variable "admin_enabled"{
  description="Whether the VLAN attachment is enabled or disabled. "
  type=bool
  default=true
}
variable "interface_name"{
  description="Name of the interface the BGP peer is associated with."
  type=string
  default="interface"
}

variable "ip_range"{
  description="IP address and range of the interface. "
  type=string
}






