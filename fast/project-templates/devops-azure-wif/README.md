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
  - [Microsoft-Hosted Agents](#microsoft-hosted-agents)
  - [Self-Hosted Agents](#self-hosted-agents)
- [Pipeline Configuration](#pipeline-configuration)
  - [Included Examples](#included-examples)
  - [Branch Policies and Permissions](#branch-policies-and-permissions)
  - [Module Authentication (Optional)](#module-authentication-optional)
<!-- END TOC -->

## Project Configuration

The provided `project.yaml` file provides an initial configuration, and makes a few assumptions that are explained in this section. This setup will only cover direct requirements for the Azure Devops integration, and assume that environment-specific customizations (project id, parent folder reference, specific IAM settings, region, etc.) will be implemented by the user.

### Organization Policies

A big part of the configuration outlined here involves setting up a Workload Identity Federation pool and provider. Depending on the organizational setup, this might require relaxing organization policies like in this example.

Comment this out of this is already in place in the parent hierarchy.

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

The services enabled at the project level include those required for hosted agents running on Compute instances, and pulling their container image from Artifact Registry. These can be commented out if only managed agents are used. Keep the rest of the services in the block, which are not shown here.

```yaml
services:
  # - artifactregistry.googleapis.com
  # - compute.googleapis.com
```

The same applies to the `vm-default` service account, which is only needed for hosted agents. The following can be commented out if only managed agents are used. Keep the rest of the definitions in both `iam_principals` and `service_accounts`, which are not shown here.

```yaml
iam_by_principals:
  # serviceAccount:vm-default@ldj-prod-net-landing-0.iam.gserviceaccount.com:
  #   - roles/artifactregistry.writer
service_accounts:
  # vm-default:
  #   display_name: VM default service account.
```

And for hosted agents instances a network is required, if using Shared VPC also edit and uncomment the following.

```yaml
# shared_vpc_service_config:
#   host_project: $project_ids:dev-spoke-0
```

## Workload Identity Federation

The pattern implemented here is the one we typically follow for infrastructure-level CI/CD, where two separate principals are used for each Terraform root module / state: a read-only one for PR checks, and a read-write one for merges.

This allows running potentially unsafe code in PR which have not yet been reviewed in a sort of sandbox, where a read-only principal is used to run checks and Terraform plan.

On the Azure Devops side, this requires setting up one Service Connection per principal, and then mapping each one to a dedicated Workload Identity pool. This is needed since the claims in the Azure Devops JWT token do not contain any information about the branch or job used for the pipeline context, and only provide the Service Connection id as a usable attribute.

This also forces using two separate pipelines for each of the principals, as the Service Connection access grants are done at the pipeline level.

### Azure Devops Service Connections

On the Azure Devops side, configure two Service Connections as explained in the ["Prepare your external IdP"](https://docs.cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines#prepare) section of the Workload Identity documentation.

Once the service connections are configured, copy their "Issuer" and "Subject identifier" attributes displayed in the Service Connection's "Workload Identity federation details", which will be used to configure the WIF providers and associated IAM roles.

Your pipelines will need to be authorized to use these service connections, but this is a simple step and you can do it when you run the pipelines for the first time. Remember to allow each pipeline usage of their respective Service Connection, so as to prevent using the read-write principal from the PR pipeline.

### GCP Workload Identity Federation Pool and Providers

Other than the issuers coming from the Service Connections, one additional source of information is also needed before we can complete the WIF providers configurations.

The providers allows defining an attribute condition, which is used to restrict the set of supported tokens. This is entirely optional, but it's good practice to define it as a preventive control, to avoid the risk of accepting tokens originating from other customers' Azure Devops organizations.

The attribute condition is a CEL expression that checks assertions in the JWT token, and the only information we can use in the tokens generated by Azure Devops are the object id of the Azure Devops enterprise application (`assertion.oid`), and the Azure tenant id (`assertion.tid`). The condition in the example below only uses `oid`, but you can mix and match depending on specific needs.

The last bit of information needed for the WIF providers configurations is the set of allowed audiences, which in this case is entirely static and contains a single object id for the AAD Token Exchange Endpoint.

Find the following definitions in the `project.yaml` file and edit them to reflect your desired values. As explained above, when multiple pipelines need to be mapped to different IAM principals on the GCP side, one Service Connection and one WIF provider are needed for each of them. The WIF pool though can stay the same. For convenience, we copy/paste the second part of subject identifier (everything after `/sc/`) in a comment, as we'll need it later when we configure IAM.

```yaml
workload_identity_pools:
  # pool name on GCP
  cicd-0:
    display_name: CI/CD pool.
    providers:
      # provider name on GCP, multiple providers are supported here
      az-test-0-ro:
        # TODO: copy everything after `/sc` in the service connection sub
        # sub: 5d2face9-4998-4294-8d24-763e98b6af3e/ddf48e36-d2cc-4aed-b863-a1c01a9c39d0
        display_name: Azure Devops test (read-only).
        # TODO: use the AZD enterprise application object id in your Entra
        # the Azure tenant id (assertion.tid) can also be used
        attribute_condition: assertion.oid=="6f90190a-864b-4915-a9b2-eef076afa596"
        attribute_mapping:
          google.subject: assertion.sub.split("/sc/")[1]
        identity_provider:
          oidc:
            # TODO: use the issuer displayed in the service connection details
            issuer_uri: https://login.microsoftonline.com/a659ec42-b896-4739-824b-1d75def8ce3a/v2.0
            # you do not need to change this
            allowed_audiences:
              - fb60f99c-7a34-4190-8149-302f77469936
      # provider name on GCP, multiple providers are supported here
      az-test-0-rw:
        # TODO: copy everything after `/sc` in the service connection sub
        # sub: 5d2face9-4998-4294-8d24-763e98b6af3e/20cef207-7699-4013-b4bf-704cebeb0037
        display_name: Azure Devops test (read-write).
        # TODO: use the same condition defined for the ro provider above
        attribute_condition: assertion.oid=="6f90190a-864b-4915-a9b2-eef076afa596"
        # TODO: use the same mapping defined for the ro provider above
        attribute_mapping:
          google.subject: assertion.sub.split("/sc/")[1]
        identity_provider:
          oidc:
            # TODO: use the issuer displayed in the service connection details
            # it should be identical to the one defined for the ro provider
            issuer_uri: https://login.microsoftonline.com/a659ec42-b896-4739-824b-1d75def8ce3a/v2.0
            # you do not need to change this
            allowed_audiences:
              - fb60f99c-7a34-4190-8149-302f77469936
```

### IAM principals

As explained above, IAM principals for Azure Devops tokens will only be able to use the assertion subject identifier as the only defining claim. Azure Devops does not populate organization, project, repository, or pipeline information in the token so each Service Connection (which defines the subject) can only be mapped to a single principal on the GCP side.

Using the subject identifier also poses a different problem, as its length is often exceeds the number of characters supported by Workload Identity Federation. This is the reason why the WIF provider mapping is defined as `assertion.sub.split("/sc/")[1]`: the subject identifier is split into two parts, and only the second part (which contains the service connection id) is kept.

So for a Service Connection that defines this subject (the read-only one in the example above):

```txt
/eid1/c/pub/t/QuxZppa4OUeCSx113vjOOg/a/rISbSSETf0KqFyZ8ppdXmA/sc/5d2face9-4998-4294-8d24-763e98b6af3e/ddf48e36-d2cc-4aed-b863-a1c01a9c39d0
```

The `google.subject` used to construct the IAM principal will only use the part after `/sc/` which is composed from your Azure Devops [organization id](https://stackoverflow.com/a/67871296) and the id of the Service Connection:

```txt
5d2face9-4998-4294-8d24-763e98b6af3e/ddf48e36-d2cc-4aed-b863-a1c01a9c39d0
```

So we finally get to the IAM principal, which for the read-only service connection above has this form:

```txt
principal://iam.googleapis.com/projects/[project number]/locations/global/workloadIdentityPools/[pool name]/subject/5d2face9-4998-4294-8d24-763e98b6af3e/ddf48e36-d2cc-4aed-b863-a1c01a9c39d0
```

The principals are of course different for the read-only and read-write pipelines, which allow us to grant them impersonation to the respective service accounts on the GCP side.

## Agent Configuration

To run pipelines one or more agent pools are needed, which can use either [Microsoft-hosted](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/hosted?view=azure-devops&tabs=windows-images%2Cyaml) or [self-hosted](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/linux-agent?view=azure-devops&tabs=IP-V4) agents (the actual instances where jobs are dispatched).

Using Microsoft-hosted agents is simpler, as there's no need to manage actual instances, but comes with the small drawbacks of having less control over the environment and tools used by the pipelines.

Self-hosted agents require a lot more configuration, but allow for customizations at the instance level, or even better to package all needed customizations (`gcloud`, `terraform`, etc.) in a Docker image.

This example uses Microsoft-hosted agents, but also provides some basic starting points for hosted agents running Docker images on GCP via Container Optimized OS.

### Microsoft-Hosted Agents

The easy path for agent selection is to use Microsoft hosted agents, which only require permissions to be granted to the relevant pipelines.

### Self-Hosted Agents

If self-hosted agents are required, a sample Container Optimized OS based agent is provided as part of this example.

Several steps are needed to bootstrap the provided example for a hosted agent:

- build the Docker image according to the [Microsoft-provided documentation](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/docker?view=azure-devops#linux)
- enable the Artifact Registry provided as part of this example via the `hosted_agent_config.create_registry` variable
- create an agent token on Azure Devops and save it to a local `token.txt` file
- apply the Terraform provided in the `self-hosted-agents` folder so that the Artifact Registry and token secrets are created
- copy the registry URL from the Terraform outputs, then tag and push the built Docker image
- configure the rest of the `hosted_agent_config` variable and apply Terraform to deploy the hosted agent

This is a sample configuration for the `hosted_agent_config` variable:

```hcl
# TODO: provide example
```

## Pipeline Configuration

### Included Examples

Three sample pipelines are provided as examples:

- a very simple pipeline that can be used to verify the credentials exchange flow
- `pr-pipeline.yaml`: A "PR pipeline" that runs Terraform init, validate, and plan on pull requests. It posts the plan output as a comment to the PR and updates the PR status.
- `merge-pipeline.yaml`: A "merge pipeline" that runs Terraform init, validate, and apply on merges to the main branch.

Each of the above pipelines needs to be edited to match your project id and resource names. Once that has been done, the code can be copy/pasted on a new pipeline in Azure Devops. On first run, you might be asked to grant permissions to the pipeline on the service connection. Refer to the Azure Devops [Pipelines Schema Reference](https://learn.microsoft.com/en-us/azure/devops/pipelines/yaml-schema/view=azure-pipelines) can be used for further customizations.

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
    *   Set the **"Contribute to pull requests"** permission to **Allow**.
    *   *Reason:* This permission is required for the pipeline to post the Terraform Plan output as a comment and to update the PR status check using the System Access Token.

3.  **Status Check Policy (Optional but Recommended):**
    *   Under **Branch Policies** -> **Status Checks**, add a new check.
    *   Status to check: `Terraform Plan` (this name must match what the pipeline posts).
    *   Policy requirement: "Required".
    *   *Reason:* This ensures the PR cannot be merged unless the Terraform Plan step in the pipeline explicitly reports "succeeded".

### Module Authentication (Optional)

The example pipelines include a step to configure Git to use the `System.AccessToken`.

```bash
git config --global url."https://$SYSTEM_ACCESSTOKEN@dev.azure.com".insteadOf "https://dev.azure.com"
```

This is only required if your Terraform configuration refers to modules hosted in *other* private repositories within the same Azure DevOps organization.

**Permissions:**
To allow the pipeline to fetch these modules, you must ensure the **Build Service** account has **Read** access to the target repository:
1.  Go to **Project Settings** -> **Repositories**.
2.  Select the repository hosting the modules.
3.  Go to **Security**.
4.  Add/Select "Project Collection Build Service" (and/or "[Project Name] Build Service").
5.  Set **Read** to **Allow**.
