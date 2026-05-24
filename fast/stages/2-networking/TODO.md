# TODO for 2-networking Stage

This document outlines the tasks required to complete the new factory-driven `2-networking` stage.

## Stage Development

- **`main.tf`:** Implement the core logic to read and parse the YAML configuration files from the `data` directory. This will involve using `yamldecode` and looping through the configurations to instantiate the necessary modules.
- **`variables.tf`:** Define the variables for the stage, including `factories_config` to specify the paths to the YAML data files.
- **`outputs.tf`:** Define the outputs for the stage, which will expose important information about the created resources (e.g., VPC IDs, subnet names).
- **`README.md`:** Write comprehensive documentation for the new stage, explaining the factory-based approach and how to configure it using the YAML files.
- **`data/defaults.yaml`:** Create a sample `defaults.yaml` file with sensible defaults for the networking stage.
- **`schemas/*.schema.json`:** Develop the JSON schemas for all the YAML configuration files to ensure validation and provide clear documentation for the expected data structures.

## Submodule Development

The following modules need to be created or reused in the `../../modules` directory. The design follows a compositional pattern where a top-level orchestrator module calls specialized, reusable factory modules.

- **`vpc-factory` (Orchestrator):** The main module for this stage. It will scan the `data/vpcs` directory. For each VPC, it will:
  - Read the main `.config.yaml` to create the core network and its associated **Cloud Routers** (defined as a list within the file).
  - Call the specialized sub-factories below, passing the appropriate paths and context.
  - Handle `peerings` and `ncc_spoke` configurations.

- **`subnet-factory`:** A specialized module that reads all YAML files within a `subnets/` directory.
- **`route-factory`:** A specialized module that reads all YAML files within a `routes/` directory.
- **`firewall-rule-factory`:** A specialized module that reads all YAML files within a `firewall-rules/` directory.
- **`psc-endpoint-factory`:** A specialized module that reads all YAML files within an `endpoints/` directory.
- **`nat-factory`:** A specialized module that reads all YAML files within a `nat/` directory.
- **`serverless-connector-factory`:** A specialized module that reads all YAML files within a `serverless-connectors/` directory.

- **`dns-factory`:** A top-level module for managing DNS zones and records.
- **`firewall-policy-factory`:** A top-level module for managing organization-level firewall policies.
- **`interconnect-factory`:** A top-level module for managing Cloud Interconnect attachments.
- **`ncc-factory`:** A top-level module for managing Network Connectivity Center (NCC) hubs.
- **`vpn-gateway-factory`:** A top-level module for managing HA VPN gateways and tunnels.

## Integration and Testing

- **Context Interpolation:** The core logic must implement a robust context interpolation mechanism (e.g., `$vpcs:`, `$ncc_hubs:`) that allows resources defined in one factory to be referenced in another. This is critical for linking resources declaratively.
- **Integration:** Integrate the new submodules into the `2-networking` stage, ensuring that the stage can correctly parse the YAML configurations and pass them to the modules.
- **Testing:** Create a comprehensive set of tests for the new stage and submodules, covering various network architectures and configurations. This should include unit tests for the modules and integration tests for the stage.
- **Documentation:** Update the main FAST documentation to reflect the new networking stage and its factory-based approach.
