# GEAP Agent Registry

This module manages the services registered in Agent Registry for a project: agents, endpoints and MCP servers.

<!-- BEGIN TOC -->
- [API](#api)
- [Registering agents, endpoints and MCP servers](#registering-agents-endpoints-and-mcp-servers)
  - [Spec content from files](#spec-content-from-files)
- [Agent Gateway integration](#agent-gateway-integration)
- [Context](#context)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## API

In order to use this module you first need to enable the `agentregistry.googleapis.com` API.

## Registering agents, endpoints and MCP servers

Services are keyed by service ID, and `type` defaults to `endpoint`. Agents and MCP servers take their spec in `content`, as a JSON string or the path to a file containing it, which sets the spec type to `A2A_AGENT_CARD` or `TOOL_SPEC`. Endpoints have no spec content. Agents registered with an agent card have no interface, while the other services have one interface built from `url` and `protocol`, which defaults to `JSONRPC` for MCP servers and to `HTTP_JSON` for endpoints.

Services are created in the module `location` unless they set their own, and `deletion_policy` applies to all of them.

```hcl
module "agent-registry" {
  source          = "./fabric/modules/geap-agent-registry"
  project_id      = var.project_id
  location        = var.region
  deletion_policy = "PREVENT"
  services = {
    weather-agent = {
      display_name = "Weather agent"
      type         = "agent"
      content = jsonencode({
        name               = "weather-agent"
        description        = "Answers questions about the weather."
        url                = "https://weather-agent-123456789.europe-west8.run.app"
        version            = "1.0.0"
        protocolVersion    = "0.3.0"
        capabilities       = {}
        defaultInputModes  = ["text/plain"]
        defaultOutputModes = ["text/plain"]
        skills = [{
          id          = "forecast"
          name        = "Forecast"
          description = "Gives the weather forecast for a location."
          tags        = ["weather"]
        }]
      })
    }
    weather-mcp = {
      description  = "Weather tools."
      display_name = "Weather MCP server"
      type         = "mcp_server"
      content      = jsonencode({ tools = [] })
      url          = "https://weather-mcp-123456789.europe-west8.run.app/mcp"
    }
    aiplatform = {
      display_name = "Vertex AI"
      url          = "https://aiplatform.googleapis.com"
    }
    aiplatform-mtls = {
      display_name = "Vertex AI (mTLS)"
      url          = "https://aiplatform.mtls.googleapis.com"
    }
    logging = {
      location = "global"
      url      = "https://logging.googleapis.com"
    }
  }
}
# tftest modules=1 resources=5 inventory=basic.yaml
```

### Spec content from files

When `content` is the path to an existing file, the module reads the spec from it, so agent cards and tool specs can live next to the configuration. Relative paths are resolved from the working directory of the root module, as with `file()`.

```hcl
module "agent-registry" {
  source     = "./fabric/modules/geap-agent-registry"
  project_id = var.project_id
  location   = var.region
  services = {
    weather-mcp = {
      display_name = "Weather MCP server"
      type         = "mcp_server"
      content      = "data/weather-mcp-tools.json"
      url          = "https://weather-mcp-123456789.europe-west8.run.app/mcp"
      protocol     = "JSONRPC"
    }
  }
}
# tftest skip
```

```json
{
  "tools": []
}
```

## Agent Gateway integration

The `id` and `registry_uris` outputs are in the format expected by the `registries` variable of the [Agent Gateway module](../geap-agent-gateway/), and the `registry_resources` output can target individual services in its `access_policies` rules.

```hcl
module "agent-registry" {
  source     = "./fabric/modules/geap-agent-registry"
  project_id = var.project_id
  location   = var.region
  services = {
    weather-mcp = {
      type     = "mcp_server"
      content  = jsonencode({ tools = [] })
      url      = "https://weather-mcp-123456789.europe-west8.run.app/mcp"
      protocol = "JSONRPC"
    }
  }
}

module "agent-gateway" {
  source      = "./fabric/modules/geap-agent-gateway"
  name        = "my-gateway"
  project_id  = var.project_id
  region      = var.region
  access_path = "egress"
  registries  = [module.agent-registry.id]
  iap_config  = {}
  access_policies = {
    egress = {
      rules = {
        weather-mcp = {
          principals    = ["group:${var.group_email}"]
          mcp_server_id = module.agent-registry.registry_resources["weather-mcp"]
        }
      }
    }
  }
}
# tftest modules=2 resources=6 inventory=gateway.yaml
```

## Context

The module supports the contexts interpolation. For example:

```hcl
module "agent-registry" {
  source     = "./fabric/modules/geap-agent-registry"
  project_id = "$project_ids:main"
  location   = "$locations:primary"
  services = {
    aiplatform = {
      url = "https://aiplatform.googleapis.com"
    }
    logging = {
      location = "$locations:shared"
      url      = "https://logging.googleapis.com"
    }
  }
  context = {
    locations = {
      primary = "europe-west1"
      shared  = "global"
    }
    project_ids = {
      main = "my-prj-id"
    }
  }
}
# tftest modules=1 resources=2 inventory=context.yaml
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [location](variables.tf#L43) | Default Agent Registry location for services: 'global', a multi-region ('us', 'eu') or a region. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L49) | The ID of the project where the Agent Registry services are created. | <code>string</code> | ✓ |  |
| [context](variables.tf#L17) | Context-specific interpolations. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [deletion_policy](variables.tf#L27) | Deletion policy applied to the registered services: 'DELETE', 'PREVENT' or 'ABANDON'. Uses the provider default when null. | <code>string</code> |  | <code>null</code> |
| [services](variables.tf#L55) | Agent Registry services, keyed by service ID. Spec content is a JSON string or the path to a file containing it: the spec type is 'NO_SPEC' when content is null, otherwise 'A2A_AGENT_CARD' for agents and 'TOOL_SPEC' for MCP servers. Agents with an agent card have no interface, so their 'url' and 'protocol' are ignored. The protocol defaults to 'JSONRPC' for MCP servers and to 'HTTP_JSON' otherwise. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [id](outputs.tf#L17) | The Agent Registry URI for the default location, in the format used by Agent Gateway 'registries'. |  |
| [registry_resource_ids](outputs.tf#L23) | The generated ids of the registered agents, endpoints and MCP servers, keyed by service ID. |  |
| [registry_resources](outputs.tf#L31) | The resource names of the registered agents, endpoints and MCP servers, keyed by service ID. |  |
| [registry_uris](outputs.tf#L39) | The Agent Registry URIs for the default location and the service locations, keyed by location. |  |
| [service_names](outputs.tf#L49) | The resource names of the registered services, keyed by service ID. |  |
| [services](outputs.tf#L56) | Service resources, keyed by service ID. |  |
<!-- END TFDOC -->
