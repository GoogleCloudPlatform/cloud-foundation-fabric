import os
import yaml
from collections import defaultdict

YAML_DIR = "../data/networks"

def load_yaml_files(directory):
    """Loads all YAML files in a directory and returns them as a list of dictionaries."""
    yaml_data = []
    for filename in os.listdir(directory):
        if filename.endswith(".yaml") or filename.endswith(".yml"):
            with open(os.path.join(directory, filename), "r") as file:
                data = yaml.safe_load(file)
                yaml_data.append(data)
    return yaml_data

def parse_vpcs(yaml_data):
    """Extracts VPCs, peerings, VPNs, and project information."""
    vpcs = {}
    peerings = set()
    vpns = set()
    external_endpoints = set()

    for data in yaml_data:
        vpc_name = data.get("name")
        project_id = data.get("project_id", "unknown-project")
        vpcs[vpc_name] = project_id

        # Parse VPC Peering
        for _, peering_config in data.get("peering_configs", {}).items():
            peer_vpc = peering_config.get("peer_network")
            if peer_vpc:
                peerings.add(tuple(sorted([vpc_name, peer_vpc])))

        # Parse VPN Configs
        for _, vpn_config in data.get("vpn_configs", {}).items():
            for peer_name, peer_config in vpn_config.get("peer_gateways", {}).items():
                if "gcp" in peer_config:
                    peer_vpc = peer_config["gcp"].split("/")[0]
                    vpns.add(tuple(sorted([vpc_name, peer_vpc])))
                elif "external" in peer_config:
                    external_endpoints.add(peer_name)  # Fixed: Correctly adds external VPN endpoint
                    vpns.add((vpc_name, peer_name))

    return vpcs, peerings, vpns, external_endpoints

def generate_mermaid(vpcs, peerings, vpns, external_endpoints):
    """Generates a Mermaid.js diagram from parsed network data."""
    mermaid = ["```mermaid", "graph TD"]

    # Create clusters for projects
    projects = defaultdict(list)
    for vpc, project in vpcs.items():
        projects[project].append(vpc)

    for project, vpc_list in projects.items():
        mermaid.append(f'    subgraph "{project}"')
        for vpc in vpc_list:
            mermaid.append(f'        {vpc}["VPC: {vpc}"]')
        mermaid.append("    end")

    # Detect bidirectional connections.  Use sets for efficient lookup.
    bidirectional_peering = {tuple(sorted(pair)) for pair in peerings}
    bidirectional_vpn = {tuple(sorted(pair)) for pair in vpns}

    # Iterate through the *bidirectional* sets.
    for vpc1, vpc2 in bidirectional_peering:
        if (vpc1, vpc2) in bidirectional_peering:  # Check against the bidirectional set
            mermaid.append(f'    {vpc1} <-->|peering| {vpc2}')
        else:
            mermaid.append(f'    {vpc1} ---|peering| {vpc2}')  # Unidirectional peering


    for vpc1, vpc2 in bidirectional_vpn:
        is_bidirectional = (vpc1, vpc2) in bidirectional_vpn
        is_external_v2 = vpc2 in external_endpoints
        is_external_v1 = vpc1 in external_endpoints

        if is_external_v1:
            arrow = "<--"
        elif is_external_v2:
            arrow = "-->"
        elif is_bidirectional:
            arrow = "<-->"
        else:
            arrow = "-->"  # Default to unidirectional

        mermaid.append(f'    {vpc1} {arrow}|VPN Tunnel| {vpc2}')



    # Add external endpoints
    for external in external_endpoints:
        mermaid.append(f'    {external}["External: {external}"]')

    mermaid.append("```")
    return "\n".join(mermaid)
  
if __name__ == "__main__":
    yaml_data = load_yaml_files(YAML_DIR)
    vpcs, peerings, vpns, external_endpoints = parse_vpcs(yaml_data)
    mermaid_diagram = generate_mermaid(vpcs, peerings, vpns, external_endpoints)

    # Save to file
    with open("network_diagram.md", "w") as f:
        f.write(mermaid_diagram)

    print("Mermaid diagram saved to network_diagram.md")
