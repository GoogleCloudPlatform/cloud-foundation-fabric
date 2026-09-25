# GEAP Agent Gateway

The module facilitates the deployments of Gemini Enterprise Agent Platform (GEAP) - Agent Gateways.

<!-- BEGIN TOC -->
- [API](#api)
- [Minimal Gateway deployment](#minimal-gateway-deployment)
- [VPC connectivity](#vpc-connectivity)
- [Connect to self-managed proxies](#connect-to-self-managed-proxies)
- [Authorizing Connectivity with IAP](#authorizing-connectivity-with-iap)
  - [Policy model](#policy-model)
  - [Authorizing access to individual services](#authorizing-access-to-individual-services)
  - [Authorizing access to the whole registry](#authorizing-access-to-the-whole-registry)
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
      domain         = "corp.internal."
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

By default, the module sets up the Identity Aware Proxy (IAP) [authorization extension](https://cloud.google.com/service-extensions/docs/lb-extensions-overview#authorization-extensions) and the `REQUEST_AUTHZ` authorization policy that binds it to the gateway. IAP evaluates every request against the Agent Registry IAM policies described below. You can customize the default configuration with the `iap_config` variable, or set it to `null` to deploy a gateway without IAP authorization.

Registering a service in Agent Registry does not by itself let agents reach it: Agent Gateway checks that the calling identity holds the `iap.webServiceVersions.egressViaIAP` permission — granted by `roles/iap.egressor` — on the destination. All access is denied unless a binding allows it, so each destination needs a binding naming the agents allowed to call it.

Agents are identified by their [agent identity](https://docs.cloud.google.com/gemini-enterprise-agent-platform/govern/agent-identity-overview), not by a service account:

- Agent Runtime, Gemini Enterprise and Cloud Run agents use built-in identities, in the form `principal://TRUST_DOMAIN/AGENT_UNIQUE_IDENTIFIER`.
- Custom and external agents use Workload Identity Federation identities, in the form `principal://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID/subject/SUBJECT`.

Agent identifiers in URN format (`urn:agent:...`) are used for catalog lookups only, and are not valid in IAM bindings.

A freshly created gateway takes a short while to become visible to the authorization policy API. If the first apply fails because a policy cannot resolve its target, re-run it.

### Policy model

IAP evaluates access against one of two mutually exclusive policy models, selected by `policy_version`. They check different permissions, so a gateway configured for one model ignores the policies of the other.

| | `V1` | `V2` |
|---|---|---|
| Model | IAM allow policies (role bindings) | [IAM Unified Access Policies](https://docs.cloud.google.com/gemini-enterprise-agent-platform/govern/policies/iam-overview-uap) |
| Permission checked | `iap.webServiceVersions.egressViaIAP` | `iap.googleapis.com/resources.egressViaIAP` |
| Granted by | `roles/iap.egressor` on the destination | a rule inside an access policy |

The default is `V1`, which is what the `registry_iam*` variables of this module produce. `V2` is accepted, but the provider cannot yet bind the IAM v3 access policies, so those policies and their bindings should be managed outside this module.

### Authorizing access to individual services

Set one of `agent_id`, `endpoint_id` or `mcp_server_id` on a `registry_iam_bindings` or `registry_iam_bindings_additive` entry to scope the grant to a single resource registered in Agent Registry, instead of to the whole registry. Each entry defaults to the gateway region, and takes an explicit `location` for services registered elsewhere.

Conditions let you narrow a grant further. On an MCP server, filtering on the `iap.googleapis.com/mcp.toolName` attribute authorizes individual tools. The `destination.*` attributes documented for [IAM access policies](https://docs.cloud.google.com/gemini-enterprise-agent-platform/govern/policies/cel-attributes-uap) belong to the `V2` policy model and do not apply here.

```hcl
module "agent-gateway" {
  source      = "./fabric/modules/geap-agent-gateway"
  name        = "my-gateway"
  project_id  = "my-project-id"
  region      = "europe-west1"
  access_path = "AGENT_TO_ANYWHERE"
  registry_iam_bindings = {
    # let a single agent call a registered REST endpoint
    billing-api = {
      members = [
        "principal://agents.global.proj-1234567890.system.id.goog/resources/aiplatform/projects/1234567890/locations/europe-west1/reasoningEngines/support-agent"
      ]
      role        = "roles/iap.egressor"
      endpoint_id = "billing-api"
    }
    # restrict the grant to specific tools of an MCP server
    weather-mcp-readonly = {
      members       = ["group:agent-developers@example.com"]
      role          = "roles/iap.egressor"
      mcp_server_id = "weather-mcp"
      condition = {
        title      = "forecast-tool-only"
        expression = "api.getAttribute('iap.googleapis.com/mcp.toolName', '') in ['get_forecast', '']"
      }
    }
  }
  registry_iam_bindings_additive = {
    # additive bindings leave members granted elsewhere untouched
    partner-agent = {
      member   = "group:agent-developers@example.com"
      role     = "roles/iap.egressor"
      agent_id = "partner-agent"
      location = "global"
    }
  }
}
# tftest inventory=registry-iam-services.yaml
```

### Authorizing access to the whole registry

`registry_iam` and `registry_iam_by_principals` grant a role across every registry listed in `registries`, or across the gateway region when the gateway governs none. Use them for blanket grants, and for destinations you want reachable without naming each one.

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
  # in {ROLE => [MEMBERS]} format
  registry_iam = {
    "roles/iap.egressor" = [
      "principal://agents.global.proj-1234567890.system.id.goog/resources/aiplatform/projects/1234567890/locations/europe-west1/reasoningEngines/support-agent"
    ]
  }
  # in {PRINCIPAL => [ROLES]} format, merged with the above
  registry_iam_by_principals = {
    "principalSet://goog/group/agent-platform@example.com" = [
      "roles/iap.egressor"
    ]
  }
}
# tftest inventory=registry-iam.yaml
```

> [!NOTE]
> Destinations that are not registered in Agent Registry cannot be targeted by these bindings, since a binding needs a registry resource to attach to. Controlling access toward unregistered hosts and paths requires the `V2` policy model.

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
      domain         = "corp.internal."
      target_network = "$networks:host"
    }
  }
  model_armor_config = {
    request_template_id  = "$model_armor_templates:request"
    response_template_id = "$model_armor_templates:response"
  }
  registry_iam = {
    "roles/iap.egressor" = ["$iam_principals:agents"]
  }
  context = {
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
| [project_id](variables.tf#L199) | The ID of the project where the data stores and the agents will be created. | <code>string</code> | ✓ |  |
| [region](variables.tf#L226) | The region where the agent gateway is created. | <code>string</code> | ✓ |  |
| [access_path](variables.tf#L17) | The direction the gateway applies to: ingress (CLIENT_TO_AGENT) or egress (AGENT_TO_ANYWHERE) (if var.is_google_managed = false). | <code>string</code> |  | <code>null</code> |
| [context](variables.tf#L47) | Context-specific interpolations. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [description](variables.tf#L64) | The description of the Agent Gateway. | <code>string</code> |  | <code>&#34;Terraform managed.&#34;</code> |
| [iap_config](variables.tf#L70) | Delegate request authorization to Identity-Aware Proxy, which enforces the Agent Registry IAM policies. Creates an authorization extension and the 'REQUEST_AUTHZ' policy binding it to the gateway. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [is_google_managed](variables.tf#L100) | Whether the Agent Gateway is Google or self-managed. | <code>bool</code> |  | <code>true</code> |
| [labels](variables.tf#L107) | Labels to associate to the Agent Gateway. | <code>map&#40;string&#41;</code> |  | <code>null</code> |
| [model_armor_config](variables.tf#L113) | Delegate content authorization to Model Armor. Creates an authorization extension and the 'CONTENT_AUTHZ' policy binding it to the gateway. Templates are not managed here: pass their ids, either fully qualified or as short ids resolved against the gateway project and region. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [networking_config](variables.tf#L136) | The Agent Gateway networking configuration. Set 'psc_i_network_attachment_id' to manage an agent connectivity template here, or 'connectivity_template_reuse' to attach the gateway to an existing one. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [project_number](variables.tf#L205) | Project number of var.project_id. Gateways reference connectivity templates by project number: set this to avoid the additional project data source read. | <code>string</code> |  | <code>null</code> |
| [proxy_uri](variables.tf#L211) | The uri of a compatible self-managed proxy (if var.is_google_managed = false). | <code>string</code> |  | <code>null</code> |
| [registries](variables.tf#L232) | A list of Agent Registries containing the agents, MCP servers and tools governed by the Agent Gateway. Note: Currently limited to project-scoped registries Must be of format //agentregistry.googleapis.com/{version}/projects/{{project}}/locations/{{location}}. | <code>list&#40;string&#41;</code> |  | <code>null</code> |
| [registry_iam](variables-iam.tf#L19) | Agent Registry IAM bindings in {ROLE => [MEMBERS]} format, applied to every registry governed by the gateway. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [registry_iam_bindings](variables-iam.tf#L26) | Authoritative Agent Registry IAM bindings in {KEY => {role = ROLE, members = [], condition = {}}} format. Set at most one of the '*_id' attributes to scope the binding to a single registered resource, or none to target the whole registry. Location defaults to the gateway region. Keys are arbitrary. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [registry_iam_bindings_additive](variables-iam.tf#L53) | Additive Agent Registry IAM bindings. Set at most one of the '*_id' attributes to scope the binding to a single registered resource, or none to target the whole registry. Location defaults to the gateway region. Keys are arbitrary. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [registry_iam_by_principals](variables-iam.tf#L80) | Authoritative Agent Registry IAM bindings in {PRINCIPAL => [ROLES]} format. Principals need to be statically defined to avoid errors. Merged internally with the 'registry_iam' variable. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [agent_gateway](outputs.tf#L17) | The Agent Gateway object. |  |
| [authz_extension_ids](outputs.tf#L22) | The authorization extension ids, keyed by service. |  |
| [authz_policy_ids](outputs.tf#L34) | The authorization policy ids, keyed by service. |  |
| [connectivity_template_id](outputs.tf#L46) | The id of the agent connectivity template attached to the gateway. |  |
| [id](outputs.tf#L51) | The Agent Gateway id. |  |
<!-- END TFDOC -->
