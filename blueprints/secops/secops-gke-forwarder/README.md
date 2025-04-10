# SecOps GKE Forwarder

This Terraform repository provides a modular and scalable solution for setting up a SecOps forwarder on Google Kubernetes Engine (GKE). This forwarder is designed to handle multi-tenant data ingestion, ensuring secure and efficient log forwarding to your Chronicle instance.

### High level architecture

The following diagram illustrates the high-level design of created resources, which can be adapted to specific requirements via variables:

![Chronicle Forwarder](./images/diagram.png)

### Key Features

- **Automated GKE Cluster Creation**: Streamlines the provisioning of a dedicated Kubernetes cluster for the forwarder.
- **Scalable Forwarder Deployment**: Deploys the Chronicle forwarder as a Kubernetes Deployment, allowing for easy scaling to accommodate varying log volumes.
- **Multi-tenant Support**: Enables the forwarder to ingest log data from multiple sources or tenants, maintaining clear separation within Chronicle.
- **Modular Configuration**: Provides flexible Terraform modules to customize network settings, resource allocation, and tenant-specific configurations.

### Deployment

#### Step 0: Cloning the repository

If you want to deploy from your Cloud Shell, click on the image below, sign in
if required and when the prompt appears, click on “confirm”.

[![Open Cloudshell](./images/cloud-shell-button.png)](https://shell.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https%3A%2F%2Fgithub.com%2FGoogleCloudPlatform%2Fcloud-foundation-fabric&cloudshell_workspace=blueprints%2Fthird-party-solutions%2Fwordpress%2Fcloudrun)

Otherwise, in your console of choice:

```bash
git clone https://github.com/GoogleCloudPlatform/cloud-foundation-fabric.git
```

Before you deploy the architecture, you will need at least the following
information/configurations in place (for more precise configuration see the Variables section):

- The project ID
- The VPC host project
- VPC and subnets should already exist

#### Step 2: Prepare the variables

Once you have the required information, head back to your cloned repository.
Make sure you’re in the directory of this tutorial (where this README is in).

Configure the Terraform variables in your `terraform.tfvars` file.
See the example test at the end of this README.md as starting point - just
copy it to `terraform.tfvars` and edit the latter. See the variables
documentation below.

#### Step 3: Prepare the providers in the root module

Setup terraform providers in the root module to deal with kubernetes resources as follows:

```terraform
data "google_client_config" "identity" {
  count = module.chronicle-forwarder.fleet_host != null ? 1 : 0
}

provider "kubernetes" {
  host  = module.chronicle-forwarder.fleet_host
  token = try(data.google_client_config.identity.0.access_token, null)
}

provider "kubectl" {
  host = module.chronicle-forwarder.fleet_host
  token = try(data.google_client_config.identity.0.access_token, null)
}
```

#### Step 4: Deploy resources

Initialize your Terraform environment and deploy the resources:

```shell
terraform init
terraform apply
```

Get kubeconfig to connect to the cluster using the command below:

```shell
gcloud container fleet memberships get-credentials CLUSTER_NAME --project PROJECT
```

Then running the command `kubectl get pods` you should receive the following message:

```
"No resources found in default namespace."
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [network_config](variables.tf#L28) | Shared VPC network configurations to use for GKE cluster. | <code title="object&#40;&#123;&#10;  host_project        &#61; optional&#40;string&#41;&#10;  network_self_link   &#61; string&#10;  subnet_self_link    &#61; string&#10;  ip_range_gke_master &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [prefix](variables.tf#L38) | Prefix used for resource names. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L57) | Project id, references existing project if `project_create` is null. | <code>string</code> | ✓ |  |
| [region](variables.tf#L62) | GCP region. | <code>string</code> | ✓ |  |
| [chronicle_forwarder](variables.tf#L17) | Chronicle GKE forwarder configuration. | <code title="object&#40;&#123;&#10;  cluster_name &#61; optional&#40;string, &#34;chronicle-log-ingestion&#34;&#41;&#10;  master_authorized_ranges &#61; optional&#40;map&#40;string&#41;, &#123;&#10;    rfc-1918-10-8 &#61; &#34;10.0.0.0&#47;8&#34;&#10;  &#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [project_create](variables.tf#L48) | Provide values if project creation is needed, uses existing project if null. Parent is in 'folders/nnn' or 'organizations/nnn' format. | <code title="object&#40;&#123;&#10;  billing_account_id &#61; string&#10;  parent             &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [tenants](variables.tf#L67) | Chronicle forwarders tenants config. | <code title="map&#40;object&#40;&#123;&#10;  chronicle_forwarder_image &#61; optional&#40;string, &#34;cf_production_stable&#34;&#41;&#10;  chronicle_region          &#61; string&#10;  tenant_id                 &#61; string&#10;  namespace                 &#61; string&#10;  forwarder_config &#61; object&#40;&#123;&#10;    config_file_content &#61; optional&#40;string&#41;&#10;    customer_id         &#61; optional&#40;string&#41;&#10;    collector_id        &#61; optional&#40;string&#41;&#10;    secret_key          &#61; optional&#40;string&#41;&#10;    tls_config &#61; optional&#40;object&#40;&#123;&#10;      required &#61; optional&#40;bool, false&#41;&#10;      cert_pub &#61; optional&#40;string&#41;&#10;      cert_key &#61; optional&#40;string&#41;&#10;    &#125;&#41;, &#123; required &#61; false &#125;&#41;&#10;  &#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [fleet_host](outputs.tf#L17) | GKE Fleet host. |  |
<!-- END TFDOC -->
## Test

```hcl
module "test" {
  source     = "./fabric/blueprints/secops/secops-gke-forwarder"
  project_id = "test"
  project_create = {
    billing_account_id = "12345-ABCDEF-12345"
    parent             = "folders/2345678901"
  }
  region = "europe-west8"
  network_config = {
    host_project        = "prod-net-landing-0"
    network_self_link   = "https://www.googleapis.com/compute/v1/projects/prod-net-landing-0/global/networks/prod-landing-0"
    subnet_self_link    = "https://www.googleapis.com/compute/v1/projects/prod-net-landing-0/regions/europe-west1/subnetworks/gke"
    ip_range_gke_master = "192.168.0.0/28"
  }
  prefix = "tmp"
  tenants = {
    tenant-1 = {
      chronicle_forwarder_image = "cf_production_stable"
      chronicle_region          = "europe"
      tenant_id                 = "tenant-1"
      namespace                 = "ten-1"
      forwarder_config = {
        config_file_content = file("data/config.yaml")
      }
    }
    tenant-2 = {
      chronicle_forwarder_image = "cf_production_stable"
      chronicle_region          = "europe"
      tenant_id                 = "tenant-2"
      namespace                 = "tenant-2"
      forwarder_config = {
        secret_key   = file("data/secret_key.json")
        customer_id  = "XXXXXXX-XXXX-XXXX-XXXX-XXXXXX"
        collector_id = "XXXXXXX-XXXX-XXXX-XXXX-XXXXXX"
      }
    }
  }
}
# tftest modules=5 resources=37 files=credentials,config
```

```
# tftest-file id=credentials path=data/secret_key.json
{
"type": "service_account",
"project_id": "xxxx",
"private_key_id": "xxxxxxxxxxxxxx",
"private_key": "-----BEGIN PRIVATE KEY-----\nsdcCDSCsLxhfQIOwdvzCn5wcwJ7xVA=\n-----END PRIVATE KEY-----\n",
"client_email": "sample@sample.iam.gserviceaccount.com",
"client_id": "ASDCVSACSA",
"auth_uri": "https://accounts.google.com/o/oauth2/auth",
"token_uri": "https://oauth2.googleapis.com/token",
"auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
"client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/sample.iam.gserviceaccount.com",
"universe_domain": "googleapis.com"
}
```

```
# tftest-file id=config path=data/config.yaml
output:
  url: malachiteingestion-pa.googleapis.com:443
  identity:
    identity:
    collector_id: COLLECTOR_ID \
    customer_id: CUSTOMER_ID \

collectors:
  - syslog:
      common:
        enabled: true
        data_type: "WINDOWS_DHCP"
        data_hint:
        batch_n_seconds: 10
        batch_n_bytes: 1048576
      tcp_address: 0.0.0.0:10514
      udp_address: 0.0.0.0:10514
      connection_timeout_sec: 60
      tcp_buffer_size: 524288
  - syslog:
      common:
        enabled: true
        data_type: "WINDOWS_DNS"
        data_hint:
        batch_n_seconds: 10
        batch_n_bytes: 1048576
      tcp_address: 0.0.0.0:10515
      connection_timeout_sec: 60
      tcp_buffer_size: 524288
```
