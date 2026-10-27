# GEAP Agent Gateway

The module facilitates the deployments of Gemini Enterprise Agent Platform (GEAP) - Agent Gateways.

<!-- BEGIN TOC -->
- [API](#api)
- [Minimal Gateway deployment](#minimal-gateway-deployment)
- [VPC connectivity](#vpc-connectivity)
- [Connect to self-managed proxies](#connect-to-self-managed-proxies)
- [Authorizing Connectivity with IAP](#authorizing-connectivity-with-iap)
  - [Policy model](#policy-model)
  - [Authorizing access to individual services and unregistered endpoints](#authorizing-access-to-individual-services-and-unregistered-endpoints)
  - [Authorizing access to the whole registry and reusing policies](#authorizing-access-to-the-whole-registry-and-reusing-policies)
  - [Enforcement mode](#enforcement-mode)
- [Screening content with Model Armor](#screening-content-with-model-armor)
- [Context](#context)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## API

In order to use this module you first need to enable the `networkservices.googleapis.com` API. Delegating authorization also needs `networksecurity.googleapis.com`, and the API of the service the decision is delegated to (`iap.googleapis.com` or `modelarmor.googleapis.com`).

## Minimal Gateway deployment

In order to deploy a gateway, you need to specify a name, a region and the direction it needs to apply to.

```hcl
module "agent-gateway" {
  source      = "./fabric/modules/geap-agent-gateway"
  name        = "my-gateway"
  project_id  = "my-project-id"
  region      = "europe-west1"
  access_path = "CLIENT_TO_AGENT" # can be also: ingress, or egress (or AGENT_TO_ANYWHERE)
}
# tftest inventory=minimal.yaml
```

## VPC connectivity

A gateway reaches your VPC network through an [agent connectivity template](https://docs.cloud.google.com/gemini-enterprise-agent-platform/govern/gateways/set-up-vpc-connectivity), a separate resource holding the egress networking settings of one or more gateways.

Set `psc_i_network_attachment_id` to have the module create the template and attach the gateway to it. The other attributes configure that template, which inherits the gateway project, region and access path, and defaults its name to the gateway name.

```hcl
module "agent-gateway" {
  source         = "./fabric/modules/geap-agent-gateway"
  name           = "my-gateway"
  project_id     = "my-project-id"
  project_number = "1234567890"
  region         = "europe-west1"
  access_path    = "AGENT_TO_ANYWHERE"
  networking_config = {
    psc_i_network_attachment_id = "projects/my-host-project/regions/europe-west1/networkAttachments/my-na"
    access_types                = ["PRIVATE"]
    vpc_egress                  = "ALL_TRAFFIC"
    dns_peering_config = {
      domains        = ["corp.internal."]
      target_network = "projects/my-host-project/global/networks/my-vpc"
    }
  }
}
# tftest inventory=connectivity-template.yaml
```

Set `connectivity_template_reuse` instead to attach the gateway to a template managed elsewhere. The two attributes are mutually exclusive, and the reference can be interpolated through the `agent_connectivity_templates` context key.

```hcl
module "agent-gateway" {
  source      = "./fabric/modules/geap-agent-gateway"
  name        = "my-gateway"
  project_id  = "my-project-id"
  region      = "europe-west1"
  access_path = "AGENT_TO_ANYWHERE"
  networking_config = {
    connectivity_template_reuse = "$agent_connectivity_templates:shared-egress"
  }
  context = {
    agent_connectivity_templates = {
      shared-egress = "projects/1234567890/locations/europe-west1/agentConnectivityTemplates/shared-egress"
    }
  }
}
# tftest inventory=connectivity-template-attach.yaml
```

> [!IMPORTANT]
> A gateway only accepts a template reference expressed with the **project number**, not the project id. The module builds that reference for you: pass `project_number` to save it a project data source read, and use the project number form when you reference a template you manage elsewhere.

## Connect to self-managed proxies

You can connect to compatible proxies you manage, by specifying the proxy uri.

```hcl
module "agent-gateway" {
  source            = "./fabric/modules/geap-agent-gateway"
  name              = "my-gateway"
  project_id        = "my-project-id"
  region            = "europe-west1"
  is_google_managed = false
  proxy_uri         = "my-proxy-uri"
}
# tftest inventory=proxy.yaml
```

## Authorizing Connectivity with IAP

By default, the module sets up the Identity-Aware Proxy (IAP) [authorization extension](https://cloud.google.com/service-extensions/docs/lb-extensions-overview#authorization-extensions) and the `REQUEST_AUTHZ` authorization policy that binds it to the gateway. IAP evaluates every request against the [IAM Unified Access Policies (UAPs)](https://docs.cloud.google.com/gemini-enterprise-agent-platform/govern/policies/iam-overview-uap) described below. You can customize the default configuration with the `iap_config` variable, or set it to `null` to deploy a gateway without IAP authorization.

Registering a service in Agent Registry does not by itself let agents reach it: Agent Gateway checks that the calling identity holds the `iap.googleapis.com/resources.egressViaIAP` permission on the destination. All access is denied unless a bound UAP rule allows it, and `DENY` rules always override `ALLOW` rules.

Before binding UAPs to a project, ensure the `constraints/iam.managed.disableAccessPolicyBindings` organization policy constraint is not enforced on the project.

Agents and callers are identified in UAP rules by IAM v3 principal URIs:

- Agent Runtime, Gemini Enterprise and Cloud Run agents use built-in identities, in the form `principal://TRUST_DOMAIN/AGENT_UNIQUE_IDENTIFIER` (or `principalSet://...` for all agents in a project/container).
- Custom and external agents use Workload Identity Federation identities, in the form `principal://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID/subject/SUBJECT`.
- Standard IAM v1 member prefixes (`user:`, `group:`, `serviceAccount:`, `domain:`, `allUsers`, `allAuthenticatedUsers`) are automatically converted by the module to their IAM v3 equivalents (`principal://goog/subject/...`, `principalSet://goog/group/...`, `principal://iam.googleapis.com/projects/-/serviceAccounts/...`, `principalSet://goog/cloudIdentityCustomerId/...`, `principalSet://goog/public:all`).

Agent identifiers in URN format (`urn:agent:...`) are used for catalog lookups only, and are not valid in IAM policies.

A freshly created gateway takes a short while to become visible to the authorization policy API. If the first apply fails because a policy cannot resolve its target, re-run it.

### Policy model

IAP evaluates access against one of two mutually exclusive policy models, selected by `iap_config.policy_version`. They check different permissions, so a gateway configured for one model ignores the policies of the other.

| | `V2` (default) | `V1` |
|---|---|---|
| Model | [IAM Unified Access Policies (IAM v3)](https://docs.cloud.google.com/gemini-enterprise-agent-platform/govern/policies/iam-overview-uap) | IAM allow policies (v1 role bindings) |
| Permission checked | `iap.googleapis.com/resources.egressViaIAP` | `iap.webServiceVersions.egressViaIAP` |
| Granted by | `ALLOW` / `DENY` rules inside a bound access policy (`access_policies`) | `roles/iap.egressor` on the destination |

The default is `V2`, which is recommended by product and is what the `access_policies` variable of this module manages (`google_iam_project_access_policy` and `google_iam_projects_policy_binding`). Consolidate related rules into a single access policy per gateway or project to stay within per-target policy binding limits.

### Authorizing access to individual services and unregistered endpoints

Each entry in `access_policies` creates a project-level UAP (`google_iam_project_access_policy`) and binds it (`google_iam_projects_policy_binding`) to the project (`target_resource = "project"`, the default) or to the gateway (`target_resource = "gateway"`).

Inside `rules`, set at most one target shortcut (`agent_id`, `endpoint_id`, `mcp_server_id`, or `registry = true`) to automatically build the destination `destination.agent_registry.*` CEL condition. Each shortcut defaults to the gateway region and accepts an explicit `location` for services registered elsewhere. If `condition` is also specified on the same rule, the module combines the shortcut condition and your custom [UAP CEL expression](https://docs.cloud.google.com/gemini-enterprise-agent-platform/govern/policies/cel-attributes-uap) with `&&`. Omit all shortcuts and set `condition` directly to govern unregistered external endpoints (`destination.unregistered.*`).

```hcl
module "agent-gateway" {
  source      = "./fabric/modules/geap-agent-gateway"
  name        = "my-gateway"
  project_id  = "my-project-id"
  region      = "europe-west1"
  access_path = "AGENT_TO_ANYWHERE"
  access_policies = {
    egress-policy = {
      display_name = "Agent Gateway Egress Policy"
      rules = {
        # let a single agent call a registered REST endpoint
        billing-api = {
          description = "Allow support agent to call billing API"
          principals = [
            "principal://agents.global.proj-1234567890.system.id.goog/resources/aiplatform/projects/1234567890/locations/europe-west1/reasoningEngines/support-agent"
          ]
          endpoint_id = "billing-api"
        }
        # allow read-only tools on a registered MCP server (group: is auto-converted to principalSet://)
        weather-mcp-readonly = {
          description   = "Allow read-only tools on weather-mcp"
          principals    = ["group:agent-developers@example.com"]
          mcp_server_id = "weather-mcp"
          condition     = "destination.agent_registry.mcp_server.tool.annotations.read_only_hint == true"
        }
        # explicitly deny a destructive tool on that MCP server
        weather-mcp-deny-delete = {
          description   = "Block delete_station tool on weather-mcp"
          effect        = "DENY"
          principals    = ["group:agent-developers@example.com"]
          mcp_server_id = "weather-mcp"
          condition     = "destination.agent_registry.mcp_server.tool.name == 'delete_station'"
        }
        # allow invoking a registered A2A agent in global
        partner-agent = {
          principals = ["group:agent-developers@example.com"]
          agent_id   = "partner-agent"
          location   = "global"
        }
        # allow POST calls to an unregistered external API
        external-ocr = {
          description = "Allow POST to external OCR service"
          principals = [
            "principal://agents.global.proj-1234567890.system.id.goog/resources/aiplatform/projects/1234567890/locations/europe-west1/reasoningEngines/support-agent"
          ]
          condition = "destination.unregistered.host == 'ocr.example.com' && destination.unregistered.path.startsWith('/v2/process') && destination.unregistered.method == 'POST'"
        }
      }
    }
  }
}
# tftest inventory=registry-iam-services.yaml
```

### Authorizing access to the whole registry and reusing policies

Setting `registry = true` on a rule authorizes access across all registries listed in `registries` (or the gateway region when `registries` is not set), unless `location` narrows it to a specific registry location.

To bind an existing organization, folder, or project access policy without creating a new policy, set `policy_reuse` to the full policy resource name.

```hcl
module "agent-gateway" {
  source      = "./fabric/modules/geap-agent-gateway"
  name        = "my-gateway"
  project_id  = "my-project-id"
  region      = "europe-west1"
  access_path = "AGENT_TO_ANYWHERE"
  registries = [
    "//agentregistry.googleapis.com/projects/my-project-id/locations/global",
    "//agentregistry.googleapis.com/projects/my-project-id/locations/europe-west1"
  ]
  access_policies = {
    registry-wide = {
      rules = {
        all-governed-registries = {
          principals = [
            "principal://agents.global.proj-1234567890.system.id.goog/resources/aiplatform/projects/1234567890/locations/europe-west1/reasoningEngines/support-agent",
            "principalSet://goog/group/agent-platform@example.com"
          ]
          registry = true
        }
      }
    }
    corp-guardrails = {
      policy_reuse = "organizations/123456789012/locations/global/accessPolicies/corp-guardrails"
    }
  }
}
# tftest inventory=registry-iam.yaml
```

### Enforcement mode

By default IAP enforces the policies (`iam_enforcement_mode` set to `null`) but you can set `iam_enforcement_mode` to `DRY_RUN` to roll policies out in audit-only mode.

```hcl
module "agent-gateway" {
  source      = "./fabric/modules/geap-agent-gateway"
  name        = "my-gateway"
  project_id  = "my-project-id"
  region      = "europe-west1"
  access_path = "AGENT_TO_ANYWHERE"
  iap_config = {
    iam_enforcement_mode = "DRY_RUN"
  }
}
# tftest inventory=iap-dry-run.yaml
```

## Screening content with Model Armor

Setting `model_armor_config` creates an authorization extension pointing at the regional Model Armor endpoint, and the `CONTENT_AUTHZ` policy that binds it to the gateway.

Model Armor templates are not managed here: create them with the `google_model_armor_template` resource and pass their ids. Ids can be fully qualified, short (resolved against the gateway project and region), or interpolated through the `model_armor_templates` context key. Templates must live in the same region as the gateway.

`authz_hosts` restricts the traffic sent to Model Armor to the listed hosts. Leave it empty to screen everything passing through the gateway.

The gateway service agent (`service-PROJECT_NUMBER@gcp-sa-dep.iam.gserviceaccount.com`) needs `roles/modelarmor.calloutUser` and `roles/serviceusage.serviceUsageConsumer` on the gateway project, and `roles/modelarmor.user` on the project holding the templates.

```hcl
module "agent-gateway" {
  source      = "./fabric/modules/geap-agent-gateway"
  name        = "my-gateway"
  project_id  = "my-project-id"
  region      = "europe-west1"
  access_path = "AGENT_TO_ANYWHERE"
  model_armor_config = {
    authz_hosts          = ["api.example.com"]
    request_template_id  = "agw-request-template"
    response_template_id = "agw-response-template"
  }
}
# tftest inventory=model-armor.yaml
```

## Context

The module supports the contexts interpolation. For example:

```hcl
module "agent-gateway" {
  source         = "./fabric/modules/geap-agent-gateway"
  name           = "my-gateway"
  project_id     = "$project_ids:main"
  project_number = "1234567890"
  region         = "$locations:primary"
  access_path    = "AGENT_TO_ANYWHERE"
  networking_config = {
    psc_i_network_attachment_id = "$psc_network_attachments:my-na"
    dns_peering_config = {
      domains        = ["corp.internal."]
      target_network = "$networks:host"
    }
  }
  model_armor_config = {
    request_template_id  = "$model_armor_templates:request"
    response_template_id = "$model_armor_templates:response"
  }
  access_policies = {
    egress = {
      rules = {
        registry = {
          principals = ["$iam_principals:agents"]
          registry   = true
        }
      }
    }
    guardrails = {
      policy_reuse = "$access_policies:guardrails"
    }
  }
  context = {
    access_policies = {
      guardrails = "organizations/123456789012/locations/global/accessPolicies/guardrails"
    }
    iam_principals = {
      agents = "group:agents@example.com"
    }
    locations = {
      primary = "europe-west1"
    }
    model_armor_templates = {
      request  = "projects/my-prj-id/locations/europe-west1/templates/request"
      response = "projects/my-prj-id/locations/europe-west1/templates/response"
    }
    networks = {
      host = "projects/my-host-prj-id/global/networks/my-vpc"
    }
    project_ids = {
      main = "my-prj-id"
    }
    psc_network_attachments = {
      my-na = "projects/my-host-prj-id/regions/europe-west1/networkAttachments/my-na"
    }
  }
}
# tftest inventory=context.yaml
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L127) | The name of the Agent Gateway. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L207) | The ID of the project where the data stores and the agents will be created. | <code>string</code> | ✓ |  |
| [region](variables.tf#L234) | The region where the agent gateway is created. | <code>string</code> | ✓ |  |
| [access_path](variables.tf#L17) | The direction the gateway applies to: ingress (CLIENT_TO_AGENT) or egress (AGENT_TO_ANYWHERE) (if var.is_google_managed = false). | <code>string</code> |  | <code>null</code> |
| [access_policies](variables-iam.tf#L19) | IAM v3 Unified Access Policies (UAPs) and their bindings, keyed by policy ID. Set 'rules' to create a project access policy and bind it, or 'policy_reuse' to bind an existing access policy. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [context](variables.tf#L47) | Context-specific interpolations. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [description](variables.tf#L65) | The description of the Agent Gateway. | <code>string</code> |  | <code>&#34;Terraform managed.&#34;</code> |
| [iap_config](variables.tf#L71) | Delegate request authorization to Identity-Aware Proxy, which enforces IAM Unified Access Policies (UAPs). Creates an authorization extension and the 'REQUEST_AUTHZ' policy binding it to the gateway. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [is_google_managed](variables.tf#L100) | Whether the Agent Gateway is Google or self-managed. | <code>bool</code> |  | <code>true</code> |
| [labels](variables.tf#L107) | Labels to associate to the Agent Gateway. | <code>map&#40;string&#41;</code> |  | <code>null</code> |
| [model_armor_config](variables.tf#L113) | Delegate content authorization to Model Armor. Creates an authorization extension and the 'CONTENT_AUTHZ' policy binding it to the gateway. Templates are not managed here: pass their ids, either fully qualified or as short ids resolved against the gateway project and region. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [networking_config](variables.tf#L136) | The Agent Gateway networking configuration. Set 'psc_i_network_attachment_id' to manage an agent connectivity template here, or 'connectivity_template_reuse' to attach the gateway to an existing one. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [project_number](variables.tf#L213) | Project number of var.project_id. Gateways reference connectivity templates by project number: set this to avoid the additional project data source read. | <code>string</code> |  | <code>null</code> |
| [proxy_uri](variables.tf#L219) | The uri of a compatible self-managed proxy (if var.is_google_managed = false). | <code>string</code> |  | <code>null</code> |
| [registries](variables.tf#L240) | A list of Agent Registries containing the agents, MCP servers and tools governed by the Agent Gateway. Note: Currently limited to project-scoped registries Must be of format //agentregistry.googleapis.com/{version}/projects/{{project}}/locations/{{location}}. | <code>list&#40;string&#41;</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [access_policy_ids](outputs.tf#L17) | The IAM v3 access policy ids, keyed by policy key. |  |
| [agent_gateway](outputs.tf#L24) | The Agent Gateway object. |  |
| [authz_extension_ids](outputs.tf#L29) | The authorization extension ids, keyed by service. |  |
| [authz_policy_ids](outputs.tf#L41) | The authorization policy ids, keyed by service. |  |
| [connectivity_template_id](outputs.tf#L53) | The id of the agent connectivity template attached to the gateway. |  |
| [id](outputs.tf#L58) | The Agent Gateway id. |  |
| [policy_binding_ids](outputs.tf#L63) | The IAM v3 policy binding ids, keyed by policy key. |  |
<!-- END TFDOC -->
