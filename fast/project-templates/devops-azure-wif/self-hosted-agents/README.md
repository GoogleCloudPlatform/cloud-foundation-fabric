# Self-Hosted Agents

If self-hosted agents are required, a sample Container Optimized OS based agent is provided as part of this example.

<!-- BEGIN TOC -->
- [Project-level Requirements](#project-level-requirements)
- [Azure Devops Requirements](#azure-devops-requirements)
- [First Terraform Apply: Docker Registry and Secret](#first-terraform-apply-docker-registry-and-secret)
- [Docker Image](#docker-image)
- [Agent Instance](#agent-instance)
- [Extending this Example](#extending-this-example)
  - [Docker Image Customizations](#docker-image-customizations)
  - [GCP Infrastructure Scale-up](#gcp-infrastructure-scale-up)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Project-level Requirements

Some requirements are needed at the project level for this example to work. If you are creating the project with the [project file provided in the parent folder](../project.yaml), simply [follow the instructions in the parent README](../README.md#hosted-vs-managed-agents), uncomment the relevant lines, and run the project factory to update the project.

If you are using a pre-existing project or you created one by hand, go through the requirements described above and mirror them in your project configuration.

One last requirement for running self-hosted agents is Internet connectivity. Check the Azure Devops documentation for details on which hosts and ports are needed.

## Azure Devops Requirements

Some additional requirements are needed on the Azure Devops side:

- [create an agent token on Azure Devops](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/personal-access-token-agent-registration?view=azure-devops) and save it to a local `token.txt` file
- define an agent pool in the organization and not down its name

## First Terraform Apply: Docker Registry and Secret

The first Terraform apply is used to create an Artifact Registry to host the custom Docker image for the agent, and the secret that contains the agent token.

Create a `terraform.tfvars` file and configure the variables needed at this stage, as in the following example. You probably should also configure a backend to persist state remotely, which is a common enough task when using Terraform and not explicitly covered here.

```hcl
agent_config = {
  # TODO: Azure Devops instance (organization)
  instance = "myorg"
  # TODO: Azure Devops agent pool name
  pool_name = "hosted agent"
  # TODO: make sure token file exists at first apply
  token = {
    file = "token.txt"
  }
}
# TODO: set GCP resource location, defaults to "europe-west8"
location = "europe-west1"
# TODO: GCP project id
project_id = "my-prj"
```

Some additional variables can be customized if their defaults don't match the desired configuration, or if the Azure Devops token changes:

- `agent_config.agent_name` defaults to "Test Agent on GCP"
- `agent_config.token.version` needs to be changed whenever a new token needs to be saved in the secret, this defaults to `1` so just bump the number if needed
- `name` name used for GCP resources, defaults to "azd"

The Azure Devops agent token in the `token.txt` file is stored in the secret using a Terraform write-only attribute: it will not be persisted in state, and the `token.txt` file is only needed on first apply and can then be removed.

If you need to change the token, for example to update expiration, simply put the new token in a `token.txt` file and increment the number in `agent_config.token.version` so the secret is updated.

Once the Terraform configuration has been saved, run `terraform init` and `terraform apply`.

## Docker Image

This example bootstraps a [self-hosted agent in Docker](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/docker?view=azure-devops#linux), so a Docker image is needed. Follow the [instructions in the Azure Devops documentation](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/docker?view=azure-devops#create-and-build-the-dockerfile-1) to prepare and build the image.

Once the image has been built, tag it and push it to the Artifact Registry. The registry URL is provided in the Terraform output, so either copy it from the `apply` run in the previous step, or run `terraform output`. The principal pushing the image needs the `roles/artifactregistry.writer` on the registry: check your project configuration and set it if it's missing.

The image can of course be customized to include the tools required by the pipelines, like for example `gcloud` or `terraform`, so as to save time at each job run.

## Agent Instance

Once the image has been pushed, edit your `terraform.tfvars` and add the instance-level configuration like in the following example.

```hcl
instance_config = {
  # TODO: full path of the Docker image
  docker_image = "europe-west8-docker.pkg.dev/tf-playground-svpc-azd-0/azd-docker/azp-agent:latest"
  # TODO: service account for the instance
  service_account = "vm-default@tf-playground-svpc-azd-0.iam.gserviceaccount.com"
  # TODO: network configuration
  vpc_config = {
    network    = "projects/ldj-dev-net-spoke-0/global/networks/dev-spoke-0"
    subnetwork = "projects/ldj-dev-net-spoke-0/regions/europe-west8/subnetworks/gce"
  }
}
```

The instance service account needs the `roles/artifactregistry.reader` role on the registry to be able to pull the image. This module automatically grants this role to the configured service account.

Once the Terraform configuration has been saved, run `terraform init` and `terraform apply`, then check that the instance is up and the agent is connected to your Azure Devops pool.

## Extending this Example

This example provides a minimal working solution, whose main goal is bringing up a working agent without changes to the assets provided in the official documentation. Once the example has been verified to be working, it's fairly easy to use it as a basis for further customizations.

### Docker Image Customizations

One simple area of improvement is the Docker image, where tools needed by the pipelines can be embedded in the image to simplify jobs and reduce run time. The main drawback of this approach is deviating from the providing agent Dockerfile, and the need to keep it sync with updates to the code provided in the documentation.

As a simple example, the following changes to the Dockerfile allow embedding gcloud and terraform in the container image by using a different base image, and slightly tweaking the original Dockerfile.

```dockerfile
# FROM python:3-alpine

FROM gcr.io/google.com/cloudsdktool/google-cloud-cli:alpine

ARG TERRAFORM_VERSION=1.14.0
ENV TARGETARCH="linux-musl-x64"

# Another option:
# FROM arm64v8/alpine
# ENV TARGETARCH="linux-musl-arm64"

# Alpine packages

RUN apk update && \
  apk upgrade && \
  apk add \
    bash curl gcc git icu-libs jq musl-dev python3-dev libffi-dev \
    openssl-dev cargo make py-pip unzip

# Terraform
RUN curl -LO https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    mv terraform /usr/local/bin/ && \
    rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# Azure CLI

RUN pip install --break-system-packages azure-cli

WORKDIR /azp/

COPY ./start.sh ./
RUN chmod 755 ./start.sh

RUN adduser -D agent
RUN chown agent ./
USER agent

# Another option is to run the agent as root.
# ENV AGENT_ALLOW_RUNASROOT="true"

ENTRYPOINT [ "./start.sh" ]
```

Another possible change is fetching the secret from within the container. This has minimal security benefits (the token would still be available via container `exec`), but removes the need of an additional systemd unit. The following snippet in the container's `start.sh` script can be used with the above Dockerfile to fetch the secret at runtime, and avoid the need to pass `AZP_TOKEN_FILE` to the container.

```bash
# Azure token from GCP secret

if [[ -n "${GCP_PROJECT}" && -n "${GCP_SECRET}" ]]; then
  gcloud secrets versions access latest \
    --secret $GCP_SECRET --project $GCP_PROJECT >/azp/token.txt
  AZP_TOKEN_FILE="/azp/token.txt"
  echo "Token retrieved from GCP secret"
else
  echo "Not retrieving token from GCP secret"
fi
```

### GCP Infrastructure Scale-up

Another customization area is on the GCP infrastructure side, where the simple instance code in this example can be easily changed to an instance template, and then wrapped into a Managed Instance Group to provide autohealing, easier scaling, or even autoscaling. This is very easy to do by leveraging the examples in the [`compute-vm`](../../../../modules/compute-vm/) and [`compute-mig`](../../../../modules/compute-mig/) modules.

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [agent_config](variables.tf#L17) | Agent configuration. | <code title="object&#40;&#123;&#10;  agent_name &#61; optional&#40;string, &#34;Test Agent on GCP&#34;&#41;&#10;  instance   &#61; string&#10;  pool_name  &#61; string&#10;  token &#61; object&#40;&#123;&#10;    file    &#61; string&#10;    version &#61; optional&#40;number, 1&#41;&#10;  &#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [project_id](variables.tf#L58) | Project id where resources will be created. | <code>string</code> | ✓ |  |
| [instance_config](variables.tf#L30) | Instance configuration. | <code title="object&#40;&#123;&#10;  docker_image    &#61; string&#10;  service_account &#61; string&#10;  zone            &#61; optional&#40;string, &#34;b&#34;&#41;&#10;  vpc_config &#61; object&#40;&#123;&#10;    network    &#61; string&#10;    subnetwork &#61; string&#10;  &#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [location](variables.tf#L45) | Location used for regional resources. | <code>string</code> |  | <code>&#34;europe-west8&#34;</code> |
| [name](variables.tf#L51) | Prefix used for resource names. | <code>string</code> |  | <code>&#34;azd&#34;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [docker_registry](outputs.tf#L17) | Docker registry URL. |  |
| [secret](outputs.tf#L22) | Azure token secret. |  |
| [ssh_command](outputs.tf#L27) | Command to SSH to the agent instance. |  |
| [vpcsc_command](outputs.tf#L35) | Command to allow egress to remotes from inside a perimeter. |  |
<!-- END TFDOC -->
