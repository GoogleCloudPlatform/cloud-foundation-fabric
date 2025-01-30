import os
import yaml
from collections import defaultdict

YAML_DIR = "../data/recipes/hub-and-spoke-peerings"
# YAML_DIR = "../data/networks"
NCC_HUBS_DIR = "../data/ncc-hubs"

def load_yaml_files(directory):
    """Loads all YAML files in a directory."""
    yaml_data = []
    for filename in os.listdir(directory):
        if filename.endswith(".yaml") or filename.endswith(".yml"):
            with open(os.path.join(directory, filename), "r") as file:
                data = yaml.safe_load(file)
                yaml_data.append(data)
    return yaml_data

def parse_vpcs(yaml_data, ncc_hub_data):
    """Extracts VPCs, peerings, VPNs, NCC hubs, etc."""
    vpcs = {}
    peerings = set()
    vpns = set()
    external_endpoints = set()
    ncc_hubs = {}
    ncc_links = set()

    for data in ncc_hub_data:
        hub_name = data.get("name")
        project_id = data.get("project_id")
        ncc_hubs[hub_name] = project_id

    for data in yaml_data:
        vpc_name = data.get("name")
        project_id = data.get("project_id")
        vpcs[vpc_name] = project_id

        for _, peering_config in data.get("peering_configs", {}).items():
            peer_vpc = peering_config.get("peer_network")
            if peer_vpc:
                peerings.add(tuple(sorted([vpc_name, peer_vpc])))

        for _, vpn_config in data.get("vpn_configs", {}).items():
            for peer_name, peer_config in vpn_config.get("peer_gateways", {}).items():
                if "gcp" in peer_config:
                    peer_vpc = peer_config["gcp"].split("/")[0]
                    vpns.add(tuple(sorted([vpc_name, peer_vpc])))
                elif "external" in peer_config:
                    external_endpoints.add(peer_name)
                    vpns.add((vpc_name, peer_name))  # Don't sort here

        for _, ncc_hub_name in data.get("ncc_configs", {}).items():
            if ncc_hub_name in ncc_hubs:
                ncc_links.add((vpc_name, ncc_hub_name))
            else:
                print(f"Warning: NCC Hub '{ncc_hub_name}' not found.")

    return vpcs, peerings, vpns, external_endpoints, ncc_hubs, ncc_links

def sanitize_mermaid_label(label):
    """Removes or replaces characters that cause problems in Mermaid labels."""
    label = label.replace("(", "[").replace(")", "]")
    return label

def generate_mermaid(vpcs, peerings, vpns, external_endpoints, ncc_hubs, ncc_links):
    """Generates a Mermaid.js diagram."""
    mermaid = ["```mermaid", "graph TD"]

    # --- Define Styles ---
    mermaid.append("    classDef nccHub fill:#f96,stroke:#333,stroke-width:2px;") # Example style

    # --- Create Subgraphs and Nodes ---
    all_projects = defaultdict(list)

    # Add VPCs to their projects
    for vpc, project in vpcs.items():
        all_projects[project].append({"type": "vpc", "name": vpc})

    # Add NCC Hubs to their projects
    for hub, project in ncc_hubs.items():
        all_projects[project].append({"type": "ncc_hub", "name": hub})

    # Generate subgraphs
    for project, entities in all_projects.items():
        mermaid.append(f'    subgraph "{project}"')
        for entity in entities:
            safe_name = sanitize_mermaid_label(entity["name"])
            if entity["type"] == "vpc":
                mermaid.append(f'        {safe_name}["VPC: {safe_name}"]')
            elif entity["type"] == "ncc_hub":
                mermaid.append(f'        {safe_name}["NCC Hub: {safe_name}"]:::nccHub') # Apply the style
        mermaid.append("    end")


    # --- Connections ---

    # Bidirectional sets (for efficient lookup)
    bidirectional_peering = {tuple(sorted(pair)) for pair in peerings}
    bidirectional_vpn = {tuple(sorted(pair)) for pair in vpns}

    # VPC Peerings
    for vpc1, vpc2 in bidirectional_peering:
        safe_vpc1 = sanitize_mermaid_label(vpc1)
        safe_vpc2 = sanitize_mermaid_label(vpc2)
        if (vpc1, vpc2) in bidirectional_peering:
            mermaid.append(f'    {safe_vpc1} <-->|Peering| {safe_vpc2}')
        else:
            mermaid.append(f'    {safe_vpc1} -->|Peering| {safe_vpc2}')

    # VPN Tunnels
    for vpc1, vpc2 in bidirectional_vpn:
        safe_vpc1 = sanitize_mermaid_label(vpc1)
        safe_vpc2 = sanitize_mermaid_label(vpc2)
        is_bidirectional = (vpc1, vpc2) in bidirectional_vpn

        if vpc1 in external_endpoints:  # Ensure external is always the *second* element
            vpc1, vpc2 = vpc2, vpc1
            safe_vpc1 = sanitize_mermaid_label(vpc1)
            safe_vpc2 = sanitize_mermaid_label(vpc2)

        if vpc2 in external_endpoints:
            mermaid.append(f'    {safe_vpc1} -->|VPN Tunnel to {safe_vpc2}| {safe_vpc2}')
        elif is_bidirectional:
            mermaid.append(f'    {safe_vpc1} <-->|VPN Tunnel| {safe_vpc2}')
        else:
            mermaid.append(f'    {safe_vpc1} -->|VPN Tunnel to {safe_vpc2}| {safe_vpc2}')

    # NCC Links
    for vpc, hub in ncc_links:
        safe_vpc = sanitize_mermaid_label(vpc)
        safe_hub = sanitize_mermaid_label(hub)
        mermaid.append(f'    {safe_vpc} -->|NCC Spoke| {safe_hub}')

    # External Endpoints
    for external in external_endpoints:
        safe_external = sanitize_mermaid_label(external)
        mermaid.append(f'    {safe_external}["External: {safe_external}"]')

    mermaid.append("```")
    return "\n".join(mermaid)

if __name__ == "__main__":
    yaml_data = load_yaml_files(YAML_DIR)
    ncc_hub_data = load_yaml_files(NCC_HUBS_DIR)
    vpcs, peerings, vpns, external_endpoints, ncc_hubs, ncc_links = parse_vpcs(yaml_data, ncc_hub_data)
    mermaid_diagram = generate_mermaid(vpcs, peerings, vpns, external_endpoints, ncc_hubs, ncc_links)
    with open("network_diagram.md", "w") as f:
        f.write(mermaid_diagram)
    print("Mermaid diagram saved to network_diagram.md")