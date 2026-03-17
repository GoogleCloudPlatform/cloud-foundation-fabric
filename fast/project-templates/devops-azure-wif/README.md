# Azure Devops Pipelines via Workload Identity Federation

<!-- BEGIN TOC -->
- [Project Configuration](#project-configuration)
  - [Organization Policies](#organization-policies)
  - [Data Access Logs](#data-access-logs)
  - [Hosted vs Managed Agents](#hosted-vs-managed-agents)
- [Workload Identity Federation](#workload-identity-federation)
  - [Azure Devops Service Connections](#azure-devops-service-connections)
  - [GCP Workload Identity Federation Pool and Providers](#gcp-workload-identity-federation-pool-and-providers)
  - [IAM principals](#iam-principals)
- [Agent Configuration](#agent-configuration)
- [Pipeline Configuration](#pipeline-configuration)
  - [Included Examples](#included-examples)
  - [Branch Policies and Permissions](#branch-policies-and-permissions)
  - [Module Authentication (Optional)](#module-authentication-optional)
<!-- END TOC -->

## Project Configuration

The provided `project.yaml` file provides an initial configuration, and makes a few assumptions that are explained in this section. This setup will only cover direct requirements for the Azure Devops integration, and assume that environment-specific customizations (project id, parent folder reference, specific IAM settings, region, etc.) will be implemented by the user.

### Organization Policies

A big part of the configuration outlined here involves setting up a Workload Identity Federation pool and provider. Depending on the organizational setup, this might require relaxing organization policies like shown in the `project.yaml` file contained in this example.

Comment this out if this constraint is enforced in the parent hierarchy.

```yaml
org_policies:
  iam.workloadIdentityPoolProviders:
    rules:
      - allow:
          all: true
```

### Data Access Logs

Workload Identity Federation often requires some amount of troubleshooting to make sure the IAM principals match the assertions in the tokens provided by the external IdP (Azure Devops in this case). This is made easier by turning on data access logs for specific services, like in this example, and also allows logging token exchanges.

Comment this out if you don't need to troubleshoot, or don't want to track token exchanges.

```yaml
data_access_logs:
  iam.googleapis.com:
    ADMIN_READ: {}
    DATA_READ: {}
    DATA_WRITE: {}
  sts.googleapis.com:
    ADMIN_READ: {}
    DATA_READ: {}
    DATA_WRITE: {}
```

### Hosted vs Managed Agents

The services enabled at the project level only include those required for Microsoft hosted agents. If you plan on running self hosted agents on Compute instances, additional configuration needs to be uncommented.

```yaml
services:
  # TODO: uncomment for self hosted agent on GCP
  # - artifactregistry.googleapis.com
  # - compute.googleapis.com
```

The same applies to the `vm-default` service account, which is only needed for self hosted agents and needs to be uncommented. Keep the rest of the definitions in both `iam_principals` and `service_accounts`, which are not shown here.

```yaml
iam_by_principals:
  # TODO: uncomment for self hosted agent on GCP
  # $iam_principals:service_accounts/_self_/vm-default:
  #   - roles/artifactregistry.reader
  #   - roles/logging.logWriter
  #   - roles/monitoring.metricWriter
service_accounts:
# TODO: uncomment for self hosted agent on GCP
  # vm-default:
  #   display_name: VM default service account.
```

And for self hosted agents instances a network is required, if using Shared VPC also edit and uncomment the following.

```yaml
# TODO: uncomment for self hosted agent on GCP
# shared_vpc_service_config:
#   host_project: $project_ids:dev-spoke-0
```

## Workload Identity Federation

The pattern implemented here is the one we typically follow for infrastructure-level CI/CD, where two separate principals are used for each Terraform root module / state: a read-only one for PR checks, and a read-write one for merges.

This allows running potentially unsafe code in PRs which have not yet been reviewed in a sort of sandbox, where a read-only principal is used to run checks and Terraform plan, thus preventing any change to resources.

On the Azure Devops side, this requires setting up one Service Connection per principal (read-only and read-write), and then mapping  to a dedicated Workload Identity provider. This is required, since the claims in the Azure Devops JWT token do not contain any information about the branch or job used for the pipeline context, and only provide the Service Connection id as a usable attribute.

This also forces using two separate pipelines for each of the principals, as the Service Connection access grants are done at the pipeline level.

### Azure Devops Service Connections

On the Azure Devops side, configure two Service Connections as explained in the ["Prepare your external IdP"](https://docs.cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines#prepare) section of the Workload Identity documentation.

Once the service connections are configured, copy the "Issuer" and "Subject identifier" attributes displayed in the Service Connection's "Workload Identity federation details", which will be used to configure the WIF providers and associated IAM principals.

Your pipelines will need to be authorized to use these service connections, but this is a simple step that is shown in the UI when the pipelines is run for the first time. Remember to allow each pipeline usage of their respective Service Connection, so as to prevent use of the read-write principal from the PR pipeline.

### GCP Workload Identity Federation Pool and Providers

Other than the issuers coming from the Service Connections, one additional source of information is also needed before we can complete the WIF providers configurations.

The providers allow defining an attribute condition, which is used to restrict the set of supported tokens. This is entirely optional, but it's good practice to define it as a preventive control, to avoid the risk of accepting tokens originating from other customers' Azure Devops organizations.

The attribute condition is a CEL expression that checks assertions in the JWT token. The only usable information presented in tokens generated by Azure Devops are the object ID of the Azure Devops enterprise application (`assertion.oid`) and the Azure tenant ID (`assertion.tid`). These IDs can be found in your Azure AD tenant, typically under 'Enterprise applications' for your Azure DevOps organization's application (for `oid`), and 'Properties' for the Tenant ID (`tid`). The condition in the example below only uses `oid`, but you can mix and match depending on specific needs.

The last bit of information needed for the WIF providers configurations is the set of allowed audiences, which in this case is entirely static and contains a single object id for the AAD Token Exchange Endpoint.

Find the following definitions in the `project.yaml` file and edit them to reflect your desired values. As explained above, when multiple pipelines need to be mapped to different IAM principals on the GCP side, one Service Connection and one WIF provider are needed for each of them. The WIF pool though can stay the same.

For convenience, we also copy/paste the second part of the subject identifiers shown in the Service Connections details (everything after `/sc/`) in a comment, as we'll need them later to configure IAM.

```yaml
workload_identity_pools:
  # pool name on GCP
  cicd-0:
    display_name: CI/CD pool.
    providers:
      # provider name on GCP, multiple providers are supported here
      az-test-0-ro:
        # TODO: copy everything after `/sc` in the service connection sub
        # sub: 5d2face9-4998-4294-8d24-763e98b6af3e/ddf48e36-d2cc-4aed-b863-abcdefghi
        display_name: Azure Devops test (read-only).
        # TODO: use the AZD enterprise application object id in your Entra
        # the Azure tenant id (assertion.tid) can also be used
        attribute_condition: assertion.oid=="6f90190a-864b-4915-a9b2-abcdefghi"
        attribute_mapping:
          google.subject: assertion.sub.split("/sc/")[1]
        identity_provider:
          oidc:
            # TODO: use the issuer displayed in the service connection details
            issuer_uri: https://login.microsoftonline.com/a659ec42-b896-4739-824b-abcdefghi/v2.0
            # you do not need to change this
            allowed_audiences:
              - fb60f99c-7a34-4190-8149-302f77469936
      # provider name on GCP, multiple providers are supported here
      az-test-0-rw:
        # TODO: copy everything after `/sc` in the service connection sub
        # sub: 5d2face9-4998-4294-8d24-763e98b6af3e/20cef207-7699-4013-b4bf-704cebeb0037
        display_name: Azure Devops test (read-write).
        # TODO: use the same condition defined for the ro provider above
        attribute_condition: assertion.oid=="6f90190a-864b-4915-a9b2-abcdefghi"
        # TODO: use the same mapping defined for the ro provider above
        attribute_mapping:
          google.subject: assertion.sub.split("/sc/")[1]
        identity_provider:
          oidc:
            # TODO: use the issuer displayed in the service connection details
            # it should be identical to the one defined for the ro provider
            issuer_uri: https://login.microsoftonline.com/a659ec42-b896-4739-824b-abcdefghi/v2.0
            # you do not need to change this
            allowed_audiences:
              - fb60f99c-7a34-4190-8149-302f77469936
```

### IAM principals

As explained above, IAM principals for Azure Devops tokens will only be able to use the assertion subject identifier as the only defining claim. Azure Devops does not populate project, repository, or pipeline information in the token so each Service Connection is only defined by its subject identifier, and can then only be mapped to a single principal on the GCP side.

Using the subject identifier also poses a different problem, as its length often exceeds the number of characters supported in Workload Identity Federation mappings. To work around this problem, the mapping is defined as `assertion.sub.split("/sc/")[1]`: the subject identifier is split into two parts, and only the second part (which contains the service connection id) is kept.

So for a Service Connection that defines this subject (the read-only one in the example above):

```txt
/eid1/c/pub/t/QuxZppa4OUeCSx113vjOOg/a/rISbSSETf0KqFyZ8ppdXmA/sc/5d2face9-4998-4294-8d24-abcdefghi/ddf48e36-d2cc-4aed-b863-abcdefghi
```

The `google.subject` mapping that identifies a IAM principal will only use the part after `/sc/`, which is composed of your Azure Devops [organization id](https://stackoverflow.com/a/67871296) and the id of the Service Connection:

```txt
5d2face9-4998-4294-8d24-abcdefghi/ddf48e36-d2cc-4aed-b863-abcdefghi
```

So we finally get to the IAM principal, which for the read-only service connection above has this form:

```txt
principal://iam.googleapis.com/projects/[project number]/locations/global/workloadIdentityPools/[pool name]/subject/5d2face9-4998-4294-8d24-abcdefghi/ddf48e36-d2cc-4aed-b863-abcdefghi
```

The principals are of course different for the read-only and read-write pipelines, allowing us to grant them impersonation to the respective service accounts on the GCP side.

## Agent Configuration

To run pipelines one or more agent pools are needed, using either [Microsoft-hosted](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/hosted?view=azure-devops&tabs=windows-images%2Cyaml) or [self-hosted](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/linux-agent?view=azure-devops&tabs=IP-V4) agents.

Using Microsoft-hosted agents is simpler as there's no need to manage actual instances, but allows less control over the environment and tools used by the pipelines (`gcloud`, `terraform`, etc.). If a tool is needed, it needs to be fetched at runtime by the pipeline either via a preconfigured [Task](https://learn.microsoft.com/en-us/azure/devops/pipelines/tasks/reference/?view=azure-pipelines) or a dedicated step.

Self-hosted agents require a lot more configuration to be set up, but allow for more customizations at the instance level. They can also be run via Docker images, which allow even simpler packaging of third-party tools.

This example uses Microsoft-hosted agents, but also provides some basic starting points for hosted agents running Docker images on GCP via Container Optimized OS. Refer to the [self-hosted-agents](./self-hosted-agents) folder documentation for more information on those.

## Pipeline Configuration

The pipelines need the [Azure Devops Terraform Task](https://marketplace.visualstudio.com/items?itemName=ms-devlabs.custom-terraform-tasks), so make sure this is available in your project.

### Included Examples

Three sample pipelines are provided as examples:

- `sample-pipeline.yaml`: a very simple pipeline that can be used to verify the credentials exchange flow
- `pr-pipeline.yaml`: a "PR pipeline" that runs Terraform init, validate, and plan on pull requests. It posts the plan output as a comment to the PR and updates the PR status.
- `merge-pipeline.yaml`: a "merge pipeline" that runs Terraform init, validate, and apply on merges to the main branch.

Each of the above pipelines needs to be edited to match your project id and resource names. Once that has been done, the code can be copy/pasted on a new pipeline in Azure Devops. On first run, you might be asked to grant permissions to the pipeline on the service connection. Refer to the Azure Devops [Pipelines Schema Reference](https://learn.microsoft.com/en-us/azure/devops/pipelines/yaml-schema/?view=azure-pipelines) can be used for further customizations.

### Branch Policies and Permissions

To enable the PR pipeline to function correctly, specifically to trigger on PR creation and post comments/status checks back to the PR, two key configurations are required in Azure DevOps:

1. **Branch Policies (Build Validation):**
    - Navigate to **Project Settings** -> **Repositories**.
    - Select your repository and go to the **Policies** tab.
    - Select the target branch (e.g., `main`).
    - Under **Build Validation**, add a new policy.
    - Select your pipeline and ensure the "Trigger" is set to "Automatic".
    - *Note:* The `pr:` trigger in the YAML file is effectively ignored unless this policy is in place.
2. **Build Service Permissions:**
    - Navigate to **Project Settings** -> **Repositories**.
    - Select your repository and go to the **Security** tab.
    - Locate the **Build Service** accounts (e.g., "Project Collection Build Service" and "[Project Name] Build Service").
    - Set the **"Contribute to pull requests"** permission to **Allow**.
    - *Reason:* This permission is required for the pipeline to post the Terraform Plan output as a comment and to update the PR status check using the System Access Token.

3. **Status Check Policy (Optional but Recommended):**
    - Under **Branch Policies** -> **Status Checks**, add a new check.
    - Status to check: `Terraform Plan` (this name must match what the pipeline posts).
    - Policy requirement: "Required".
    - *Reason:* This ensures the PR cannot be merged unless the Terraform Plan step in the pipeline explicitly reports "succeeded".

### Module Authentication (Optional)

If the Terraform code references modules from a private Azure repository (instead of local files, or a public repository), some further configuration is needed. The following assumes that the modules repository is in the same Azure Devops project, if the repository is in a different project some additional configuration steps are needed, they are not outlined here as this is beyond the scope of this example.

The example pipelines include a step to configure Git to use the `System.AccessToken`.

```bash
git config --global url."https://$SYSTEM_ACCESSTOKEN@dev.azure.com".insteadOf "https://dev.azure.com"
```

**Permissions:**

To allow the pipeline to fetch these modules, you must ensure the **Build Service** account has **Read** access to the target repository, and the pipeline itself is explicitly granted access:

- Go to **Project Settings** -> **Repositories**.
- Select the repository hosting the modules.
- Go to **Security**.
- Add/Select "Project Collection Build Service" (and/or "[Project Name] Build Service").
- Set **Read** to **Allow**.
- In the same **Security** dialog, locate the "Pipelines" section. Explicitly add your pipeline(s) (e.g., `pr-pipeline`, `merge-pipeline`) and grant them **Read** access to this repository. This provides an additional layer of authorization for specific pipeline runs.

**Important:** You must also disable a restrictive default setting that limits token scope:

- Go to **Project Settings** -> **Pipelines** -> **Settings**.
- Ensure **"Protect access to repositories in YAML pipelines"** (or "Limit job authorization scope to referenced Azure DevOps repositories") is **Disabled (Unchecked)**. If enabled, this setting prevents the System Access Token from accessing repositories even if permissions are granted.
