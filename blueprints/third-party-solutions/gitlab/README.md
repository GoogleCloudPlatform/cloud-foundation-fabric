# Gitlab Blueprint

This blueprint is responsible for provisioning a production ready Gitlab instance on the landing zone infrastructure. The [reference architecture](https://docs.gitlab.com/ee/administration/reference_architectures/1k_users.html) of this deployment target 1K users, updates to the current code is required in of HA and/or higher capacity requirements.

The following diagram illustrates the high-level design of created resources, which can be adapted to specific requirements via variables:

<p align="center">
  <img src="diagram.png" alt="Gitlab">
</p>

## Table of contents

<!-- TOC -->
* [Gitlab Blueprint](#gitlab-blueprint)
  * [Table of contents](#table-of-contents)
  * [Managed Services for Seamless Operations](#managed-services-for-seamless-operations)
    * [Object Storage <-> Google Cloud Storage](#object-storage-----google-cloud-storage)
  * [Identity](#identity)
    * [SAML Integration](#saml-integration)
      * [Google Workspace Setup](#google-workspace-setup)
    * [Others Identity Integration](#others-identity-integration)
  * [Email](#email)
    * [Sendgrid integration](#sendgrid-integration)
  * [SSL Certificate Configuration](#ssl-certificate-configuration)
  * [Networking and scalability](#networking-and-scalability)
  * [HA](#ha)
    * [Deployment](#deployment)
      * [Step 0: Cloning the repository](#step-0--cloning-the-repository)
      * [Step 2: Prepare the variables](#step-2--prepare-the-variables)
      * [Step 3: Deploy resources](#step-3--deploy-resources)
      * [Step 4: Use the created resources](#step-4--use-the-created-resources)
  * [Reference and useful links](#reference-and-useful-links)
  * [Files](#files)
  * [Variables](#variables)
  * [Outputs](#outputs)
<!-- TOC -->

## Managed Services for Seamless Operations

This Gitlab installation prioritizes the use of Google Cloud managed services to
streamline infrastructure management and optimization. Here's a breakdown of the
managed services incorporated:

1. [Google Cloud Storage](https://cloud.google.com/storage): is a highly
   scalable and secure object storage service for storing and accessing data in
   Google Cloud.<br/><br/>
2. [Cloud SQL PostgreSQL](https://cloud.google.com/sql/docs/postgres): Cloud SQL
   for Postgres is a fully managed database service on Google Cloud Platform. It
   eliminates database administration tasks, allowing you to focus on your
   application, while offering high performance, automatic scaling, and secure
   management of your PostgreSQL databases.<br/><br/>
3. [Memorystore](https://cloud.google.com/memorystore?hl=en): GCP Memorystore
   offers a fully managed Redis service for in-memory data caching and
   high-performance data access.

Benefits:

- Reduced Operational Overhead: Google handles infrastructure setup,
  maintenance, and updates, freeing up your time and resources.
- Enhanced Security: Managed services often benefit from Google's comprehensive
  security measures and expertise.
- Scalability: Easily adjust resource allocation to meet evolving demands.
- Cost Optimization: Pay for the resources you use, benefiting from Google's
  infrastructure optimization.
  Integration: Managed services seamlessly integrate with other GCP services,
  promoting a cohesive cloud environment.
  This module embraces managed services to deliver a resilient, scalable, and
  cost-effective application architecture on Google Cloud.

### Object Storage <-> Google Cloud Storage

GitLab supports using an object storage service for holding numerous types of
data. It’s recommended over NFS and in general it’s better in larger setups as
object storage is typically much more performant, reliable, and scalable.

A single storage connection to Cloud Storage is configured for all object types,
which leverages default Google Compute Engine credential (the so called "
consolidated form"). A Cloud Storage bucket is bootstrapped for each object
type, the table below summarized such a configuration:

| Object Type      | Description                            | Cloud Storage Bucket              |
|------------------|----------------------------------------|-----------------------------------|
| artifacts	       | CI artifacts                           | ${prefix}-gitlab-artifacts        |
| external_diffs   | Merge request diffs                    | ${prefix}-mr-diffs                |
| uploads	         | User uploads                           | ${prefix}-gitlab-uploads          |
| lfs	             | Git Large File Storage objects         | ${prefix}-gitlab-lfs              |
| packages	        | Project packages (e.g. PyPI, Maven ..) | ${prefix}-gitlab-packages         |
| dependency_proxy | Dependency Proxy                       | ${prefix}-gitlab-dependency-proxy |
| terraform_state  | Terraform state files                  | ${prefix}-gitlab-terraform-state  |
| pages	           | Pages                                  | ${prefix}-gitlab-pages            |

For more information on Gitlab object storage and Google Cloud Storage
integration please refer to the official Gitlab documentation available at the
following [link](https://docs.gitlab.com/ee/administration/object_storage.html).

- [PostgreSQL service](https://docs.gitlab.com/ee/administration/postgresql/external.html)

Updated postgres configuration to match documentation, created required database
in postgres instance.

- [Redis](https://docs.gitlab.com/ee/administration/redis/replication_and_failover_external.html)

## Identity

GitLab integrates with a number of OmniAuth providers as well as external
authentication and authorization providers such as Google Secure LDAP and many
other providers.
At this time this stage can deal with SAML integration for both user
authentication and provisioning, in order to setup SAML integration please
provide the saml block on gitlab_config variable.

### SAML Integration

This section details how configure GitLab to act as a SAML service provider (
SP). This allows GitLab to consume assertions from a SAML identity provider (
IdP), such as Cloud Identity, to authenticate users. Please find instructions
below for integration with:

- [Google Workspace](#google-workspace-setup)

#### Google Workspace Setup

Setup of Google Workspace is documented in the official Gitlab documentation
available at the
following [link](https://docs.gitlab.com/ee/integration/saml.html#set-up-google-workspace)
which are also reported below for simplicity.

Create a custom SAML webapp following instructions available at the
following [link](https://support.google.com/a/answer/6087519), providing these
information in the service provider configuration:

| Configuration     | Typical Value                                    | Cloud Storage Bucket                                                                        |
|-------------------|--------------------------------------------------|---------------------------------------------------------------------------------------------|
| Name of SAML App	 | Gitlab                                           | Name of the app                                                                             |
| ACS URL           | https://<GITLAB_DOMAIN>/users/auth/saml/callback | Assertion Consumer Service URL.                                                             |
| GITLAB_DOMAIN	    | gitlab.example.com                               | Your GitLab instance domain.                                                                |
| Entity ID	        | https://gitlab.example.com                       | A value unique to your SAML application. Set it to the issuer in your GitLab configuration. |
| Name ID	          | EMAIL                                            | Required value. Also known as name_identifier_format.                                       |

Then setup the following SAML attribute mappings:

| Google Directory attributes    | App attributes |
|--------------------------------|----------------|
| Basic information > Email      | email          |
| Basic Information > First name | first_name     |
| Basic Information > Last name  | last_name      |

After configuring the Google Workspace SAML application, record the following
information:

| Value                  | Description                                                                                                                                                    |
|------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| SSO URL                | Setup in gitlab_config.saml.sso_target_url variable                                                                                                            |
| Certificate (download) | Setup in gitlab_config.saml.idp_cert_fingerprint (obtain value with the following command `openssl x509 -in <your_certificate.crt> -noout -fingerprint -sha1`) |

### Others Identity Integration

- [OpenID Connect OmniAuth](https://docs.gitlab.com/ee/administration/auth/oidc.html#configure-google)
- [Google Secure LDAP](https://docs.gitlab.com/ee/administration/auth/ldap/google_secure_ldap.html)

## Email

- [Gmail/Workspace](https://docs.gitlab.com/ee/administration/incoming_email.html#gmail)

### Sendgrid integration

Use
the [Google Cloud Marketplace](https://console.cloud.google.com/marketplace/details/sendgrid-app/sendgrid-email)
to sign up for the SendGrid email service. Make a note of your SendGrid SMTP
account credentials, which include username, password, and hostname. Your SMTP
username and password are the same as what you used to sign up for the service.
The SendGrid hostname is smtp.sendgrid.net.
Create an API key:
Sign in to SendGrid and go to Settings > API Keys.

1. Create an API key.
2. Select the permissions for the key. At a minimum, the key must have Mail send
   permissions to send email.
3. Click Save to create the key.
4. SendGrid generates a new key. This is the only copy of the key, so make sure
   that you copy the key and save it for later.

Configure the sendgrid API key in the gitlab_config variable, under mail,
sendgrid arguments as per the following example:

```terraform
gitlab_config = {
  hostname = "gitlab.example.com"
  mail     = {
    sendgrid = {
      api_key = "test"
    }
  }
}
```

## SSL Certificate Configuration

This module provides flexibility in configuring SSL certificates for the server.
You have two options:

1. **Provide Your Own Certificates**: If you have existing SSL certificates, you
   can place them in the certs folder within the module's directory. The module
   will automatically detect and use them.
   File Names: Ensure the files are named ${gitlab_hostname}.crt (for the
   certificate) and
   gitlab_hostname.key (for the private key). Although it is not required in
   this stage it is mandatory to also place inside the certs folder the server
   CA certificate which is later use to secure HTTPS access from the Gitlab
   runner. Name of the CA certificate should be: ${gitlab_hostname}.ca.crt
2. **Use Automatically Generated Self-Signed Certificates**: If you don't
   provide certificates, the module will generate a self-signed certificate for
   immediate use.
   Updating Later: You can replace the self-signed certificate with your own
   certificates at any time by placing them in the certs folder and re-running
   Terraform.

**Important Notes:**

Certificate Validation: Self-signed certificates are not validated by browsers
and will trigger warnings. Use them only for development or testing
environments.

For more information on how to configure HTTPS on Gitlab please refer to the
original Gitlab documentation available at the
following [link](https://docs.gitlab.com/omnibus/settings/ssl/#configure-https-manually).

## Networking and scalability

- [Load balancer](https://docs.gitlab.com/ee/administration/load_balancer.html)

## HA

- [High Availability](http://ubimol.it/12.0/ee/administration/high_availability/README.html)

### Deployment

#### Step 0: Cloning the repository

If you want to deploy from your Cloud Shell, click on the image below, sign in
if required and when the prompt appears, click on “confirm”.

[![Open Cloudshell](../../../assets/images/cloud-shell-button.png)](https://shell.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https%3A%2F%2Fgithub.com%2FGoogleCloudPlatform%2Fcloud-foundation-fabric&cloudshell_workspace=blueprints%2Fthird-party-solutions%2Fwordpress%2Fcloudrun)

Otherwise, in your console of choice:

```bash
git clone https://github.com/GoogleCloudPlatform/cloud-foundation-fabric
```

Before you deploy the architecture, you will need at least the following
information (for more precise configuration see the Variables section):

* The project ID

The VPC host project, VPC and subnets should already exist and the following networking requirements are satisfied:
- configured PSA for Cloud SQL on the VPC
- subnets configured with PGA and Cloud NAT for internet access
- Inbound firewall rule for IAP on port 22
- Inbound firewall rule for TCP ports 80, 443, 2222 from proxy subnet CIDR (gitlab)

#### Step 2: Prepare the variables

Once you have the required information, head back to your cloned repository.
Make sure you’re in the directory of this tutorial (where this README is in).

Configure the Terraform variables in your `terraform.tfvars` file.
See [terraform.tfvars.sample](terraform.tfvars.sample) as starting point - just
copy it to `terraform.tfvars` and edit the latter. See the variables
documentation below.

#### Step 3: Deploy resources

Initialize your Terraform environment and deploy the resources:

```shell
terraform init
terraform apply
```

#### Step 4: Use the created resources

Connect to squid-proxy for accessing gitlab instance using the gcloud command
available in the `ssh_to_bastion` terraform output.

```bash
terraform output ssh_to_bastion
```

A gcloud command like the following should be available

```bash 
gcloud compute ssh squid-vm --project ${project} --zone europe-west8-b -- -L 3128:127.0.0.1:3128 -N -q -f
```

Set as system proxy ip 127.0.0.1 and port 3128 and connect to Gitlab hostname https://gitlab.gcp.example.com.
Use default admin password available in /run/gitlab/config/initial_root_password or reset admin password via the following command on the Docker container:

```bash
gitlab-rake “gitlab:password:reset”
```

## Reference and useful links

- [Reference architecture up to 1k users](https://docs.gitlab.com/ee/administration/reference_architectures/1k_users.html)
- [`/etc/gitlab/gitlab.rb` template](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template)
- [`/etc/gitlab/gitlab.rb` default options](https://docs.gitlab.com/ee/administration/package_information/defaults.html)

<!-- TFDOC OPTS files:1 show_extra:1 -->
<!-- BEGIN TFDOC -->

## Files

| name | description | modules | resources |
|---|---|---|---|
| [3-gitlab-providers.tf](./3-gitlab-providers.tf) | None |  |  |
| [gitlab.tf](./gitlab.tf) | None | <code>compute-vm</code> · <code>iam-service-account</code> · <code>net-lb-int</code> | <code>google_dns_record_set</code> |
| [main.tf](./main.tf) | Module-level locals and resources. | <code>project</code> · <code>squid-proxy</code> |  |
| [outputs-files.tf](./outputs-files.tf) | Output files persistence to local filesystem. |  | <code>local_file</code> |
| [outputs-gcs.tf](./outputs-gcs.tf) | None |  | <code>google_storage_bucket_object</code> |
| [outputs.tf](./outputs.tf) | Module outputs. |  |  |
| [services.tf](./services.tf) | None | <code>cloudsql-instance</code> · <code>gcs</code> | <code>google_redis_instance</code> |
| [ssl.tf](./ssl.tf) | None |  | <code>tls_cert_request</code> · <code>tls_locally_signed_cert</code> · <code>tls_private_key</code> · <code>tls_self_signed_cert</code> |
| [variables.tf](./variables.tf) | Module variables. |  |  |

## Variables

| name | description | type | required | default | producer |
|---|---|:---:|:---:|:---:|:---:|
| [automation](variables.tf#L20) | Automation resources created by the bootstrap stage. | <code title="object&#40;&#123;&#10;  outputs_bucket          &#61; string&#10;  project_id              &#61; string&#10;  project_number          &#61; string&#10;  federated_identity_pool &#61; string&#10;  federated_identity_providers &#61; map&#40;object&#40;&#123;&#10;    audiences        &#61; list&#40;string&#41;&#10;    issuer           &#61; string&#10;    issuer_uri       &#61; string&#10;    name             &#61; string&#10;    principal_branch &#61; string&#10;    principal_repo   &#61; string&#10;  &#125;&#41;&#41;&#10;  service_accounts &#61; object&#40;&#123;&#10;    resman-r &#61; string&#10;  &#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>0-bootstrap</code> |
| [billing_account](variables.tf#L42) | Billing account id. If billing account is not part of the same org set `is_org_level` to `false`. To disable handling of billing IAM roles set `no_iam` to `true`. | <code title="object&#40;&#123;&#10;  id           &#61; string&#10;  is_org_level &#61; optional&#40;bool, true&#41;&#10;  no_iam       &#61; optional&#40;bool, false&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>0-bootstrap</code> |
| [folder_ids](variables.tf#L53) | Folder to be used for the gitlab resources in folders/nnnn format. | <code title="object&#40;&#123;&#10;  gitlab &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>1-resman</code> |
| [host_project_ids](variables.tf#L88) |  | <code title="object&#40;&#123;&#10;  dev-spoke-0  &#61; string&#10;  prod-landing &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |  |
| [locations](variables.tf#L95) | Optional locations for GCS, BigQuery, and logging buckets created here. | <code title="object&#40;&#123;&#10;  bq      &#61; string&#10;  gcs     &#61; string&#10;  logging &#61; string&#10;  pubsub  &#61; list&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>0-bootstrap</code> |
| [prefix](variables.tf#L113) |  | <code>string</code> | ✓ |  |  |
| [gitlab_config](variables.tf#L61) |  | <code title="object&#40;&#123;&#10;  hostname &#61; optional&#40;string, &#34;gitlab.gcp.example.com&#34;&#41;&#10;  mail &#61; optional&#40;object&#40;&#123;&#10;    enabled &#61; optional&#40;bool, false&#41;&#10;    sendgrid &#61; optional&#40;object&#40;&#123;&#10;      api_key        &#61; optional&#40;string&#41;&#10;      email_from     &#61; optional&#40;string, null&#41;&#10;      email_reply_to &#61; optional&#40;string, null&#41;&#10;    &#125;&#41;, null&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  saml &#61; optional&#40;object&#40;&#123;&#10;    forced                 &#61; optional&#40;bool, false&#41;&#10;    idp_cert_fingerprint   &#61; string&#10;    sso_target_url         &#61; string&#10;    name_identifier_format &#61; optional&#40;string, &#34;urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress&#34;&#41;&#10;  &#125;&#41;, null&#41;&#10;  ha_required  &#61; optional&#40;bool, false&#41;&#10;  architecture &#61; optional&#40;string, &#34;CENTRALIZED&#34;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [outputs_location](variables.tf#L107) | Path where providers and tfvars files for the following stages are written. Leave empty to disable. | <code>string</code> |  | <code>null</code> |  |
| [regions](variables.tf#L117) | Region definitions. | <code title="object&#40;&#123;&#10;  primary   &#61; string&#10;  secondary &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  primary   &#61; &#34;europe-west1&#34;&#10;  secondary &#61; &#34;europe-west4&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |  |
| [subnet_self_links](variables.tf#L129) | Shared VPC subnet self links. | <code title="object&#40;&#123;&#10;  dev-spoke-0  &#61; map&#40;string&#41;&#10;  prod-landing &#61; map&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> | <code>2-networking</code> |
| [vpc_self_links](variables.tf#L139) | Shared VPC self links. | <code title="object&#40;&#123;&#10;  dev-spoke-0  &#61; string&#10;  prod-landing &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> | <code>2-networking</code> |

## Outputs

| name | description | sensitive | consumers |
|---|---|:---:|---|
| [postgresql_users](outputs.tf#L25) |  | ✓ |  |
| [ssh_to_bastion](outputs.tf#L30) | gcloud command to ssh bastion host proxy. | ✓ |  |
| [ssh_to_gitlab](outputs.tf#L36) | gcloud command to ssh gitlab instance. | ✓ |  |

<!-- END TFDOC -->
