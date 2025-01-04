# Network Security

This stage enables NGFW Enterprise in the dev `dev` and `prod` VPCs. This includes:

- security profiles
- security profile groups
- NGFW endpoints
- NGFW endpoint associations
- global network firewall policies and some recommended firewall policy rules

The following diagram is a high level reference of the resources created and managed here (excludes projects and VPCs):

<p align="center">
  <img src="diagram.png" alt="Network security NGFW diagram">
</p>

<!-- BEGIN TOC -->
- [Design overview and choices](#design-overview-and-choices)
- [How to run this stage](#how-to-run-this-stage)
  - [Provider and Terraform variables](#provider-and-terraform-variables)
  - [Impersonating the automation service account](#impersonating-the-automation-service-account)
  - [Variable configuration](#variable-configuration)
  - [Running the stage](#running-the-stage)
- [Customizations](#customizations)
  - [Firewall policy rules factories](#firewall-policy-rules-factories)
  - [NGFW Enterprise configuration](#ngfw-enterprise-configuration)
- [Files](#files)
- [Variables](#variables)
<!-- END TOC -->

## Design overview and choices

- We create one security profile (and security profile group) per environment in the spoke VPCs only. That's usually where inspection is needed, as it's where workloads run.
- By default, we create NGFW Enterprise endpoints in three zones in the default, primary region (europe-west1). You can adapt this, depending on where your workloads run, using the dedicated variable.
- We install default firewall policy rules in each spoke, so that we allow and inspect all traffic going to the Internet and we allow egress towards RFC-1918 addresses. In ingress, you'll need to add your own rules. We provided some examples that need to be adapted to your topology (number of regions, subnets).
- We use global network firewall policies, as legacy VPC firewall rules are not compatible with NGFW Enterprise. These policies coexist with the legacy VPC firewall rules that we create in the netwroking stage.
- For your convenience, firewall policy rules leverage factories, so that you can define firewall policy rules using yaml files. The path of these files is configurable. Look in the [Customization](#customizations) section for more details.
- NGFW Enterprise endpoints are org-level resources that need to reference a quota project for billing purposes. By default, we create a dedicated `xxx-net-ngfw-0` quota project. Anyway, you can choose to leverage an existing project. Look in the [Customization](#customizations) section for more details.
- Firewall endpoint associations in this stage can reference TLS inspection policies created in the [2-security stage](../2-security/README.md). More info in the customization section of this document.
- While TLS inspection policies are created in the [2-security stage](../2-security/README.md), FAST still allows the service accounts of this stage and the `gcp-network-admins` group to create and manage them anywhere in the organization.

## How to run this stage

This stage is meant to be executed after any [networking](../2-networking-a-simple) stage has run and it leverages dedicated automation service accounts and a bucket created in the [resman](../1-resman) stage.

It's to run this stage in isolation, but that's outside the scope of this document, and you would need to refer to the code for the bootstrap and resman stages for the roles needed.

Before running this stage, you need to make sure you have the correct credentials and permissions, and localize variables by assigning values that match your configuration.

### Provider and Terraform variables

As all other FAST stages, the [mechanism used to pass variable values and pre-built provider files from one stage to the next](../0-bootstrap/README.md#output-files-and-cross-stage-variables) is also leveraged here.

The commands to link or copy the provider and terraform variable files can be easily derived from the `fast-links.sh` script in the FAST stages folder, passing it a single argument with the local output files folder (if configured) or the GCS output bucket in the automation project (derived from stage 0 outputs). The following examples demonstrate both cases, and the resulting commands that then need to be copy/pasted and run.

```bash
../fast-links.sh ~/fast-config

# File linking commands for network securoty (optional) stage

# provider file
ln -s ~/fast-config/fast-test-00/providers/2-network-security-providers.tf ./

# input files from other stages
ln -s ~/fast-config/fast-test-00/tfvars/0-globals.auto.tfvars.json ./
ln -s ~/fast-config/fast-test-00/tfvars/0-bootstrap.auto.tfvars.json ./
ln -s ~/fast-config/fast-test-00/tfvars/1-resman.auto.tfvars.json ./

# conventional place for stage tfvars (manually created)
ln -s ~/fast-config/fast-test-00/2-network-security.auto.tfvars ./

# optional files
ln -s ~/fast-config/fast-test-00/2-networking.auto.tfvars.json ./
ln -s ~/fast-config/fast-test-00/2-security.auto.tfvars.json ./
```

```bash
../fast-links.sh gs://xxx-prod-iac-core-outputs-0

# File linking commands for network securoty (optional) stage

# provider file
gcloud storage cp gs://xxx-prod-iac-core-outputs-0/providers/2-network-security-providers.tf ./

# input files from other stages
gcloud storage cp gs://xxx-prod-iac-core-outputs-0/tfvars/0-globals.auto.tfvars.json ./
gcloud storage cp gs://xxx-prod-iac-core-outputs-0/tfvars/0-bootstrap.auto.tfvars.json ./
gcloud storage cp gs://xxx-prod-iac-core-outputs-0/tfvars/1-resman.auto.tfvars.json ./

# conventional place for stage tfvars (manually created)
gcloud storage cp gs://xxx-prod-iac-core-outputs-0/2-network-security.auto.tfvars ./

# optional files
gcloud storage cp gs://xxx-prod-iac-core-outputs-0/2-networking.auto.tfvars.json ./
gcloud storage cp gs://xxx-prod-iac-core-outputs-0/2-security.auto.tfvars.json ./
```

### Impersonating the automation service account

The preconfigured provider file uses impersonation to run with this stage's automation service account's credentials. The `gcp-devops` and `organization-admins` groups have the necessary IAM bindings in place to do that, so make sure the current user is a member of one of those groups.

### Variable configuration

Variables in this stage -- like most other FAST stages -- are broadly divided into three separate sets:

- variables which refer to global values for the whole organization (org id, billing account id, prefix, etc.), which are pre-populated via the `0-globals.auto.tfvars.json` file linked or copied above
- variables which refer to resources managed by previous stages, which are prepopulated here via the `0-bootstrap.auto.tfvars.json`, `1-resman.auto.tfvars.json` and `2-networking.auto.tfvars.json` files linked or copied above
- and finally variables that optionally control this stage's behaviour and customizations, and can to be set in a custom `terraform.tfvars` file

The latter set is explained in the [Customization](#customizations) sections below, and the full list can be found in the [Variables](#variables) table at the bottom of this document.

Note that the `outputs_location` variable is disabled by default, you need to explicitly set it in your `terraform.tfvars` file if you want output files to be generated by this stage. This is a sample `terraform.tfvars` that configures it, refer to the [bootstrap stage documentation](../0-bootstrap/README.md#output-files-and-cross-stage-variables) for more details:

```tfvars
outputs_location = "~/fast-config"
```

### Running the stage

Once provider and variable values are in place and the correct user is configured, the stage can be run:

```bash
terraform init
terraform apply
```

## Customizations

You can optionally customize a few options adding a `terraform.tfvars` file to this stage.

### Firewall policy rules factories

By default, firewall policy rules yaml files are contained in the `data` folder within this module. Anyway, you can customize this location.

### NGFW Enterprise configuration

You can decide the zones where to deploy the NGFW Enterprise endpoints. These are set by default to `europe-west1-b`, `europe-west1-c` and `europe-west1-d`.

```tfvars
ngfw_enterprise_config = {
  endpoint_zones = [
    "us-east4-a",
    "us-east4-b",
    "australia-southeast1-b",
    "australia-southeast1-c"
  ]
}
```

Instead of creating a dedicated NGFW Enterprise billing/quota project, you can choose to leverage an existing project. These can even be one of your existing networking projects.
You'll need to make sure your network security service account can activate the `networksecurity.googleapis.com` on that project (for example, assigning the `roles/serviceusage.serviceUsageAdmin` role).

```tfvars
ngfw_enterprise_config = {
  quota_project_id = "your-quota-project-id"
}
```

You can optionally enable TLS inspection in stage [2-security](../2-security/README.md).
Ingesting outputs from [stage 2-security](../2-security/README.md), this stage will configure TLS inspection in NGFW Enterprise and will reference the CAs and the trust-configs you created in [stage 2-security](../2-security/README.md).
Make sure the CAs and the trusted configs created for NGFW Enterprise in the [2-security stage](../2-security/README.md) match the region where you defined your zonal firewall endpoints.

<!-- TFDOC OPTS files:1 show_extra:1 exclude:2-network-security-providers.tf -->
<!-- BEGIN TFDOC -->
## Files

| name | description | modules | resources |
|---|---|---|---|
| [main.tf](./main.tf) | Module-level locals and resources. | <code>project</code> |  |
| [ngfw.tf](./ngfw.tf) | NGFW Enteprise resources. |  | <code>google_network_security_firewall_endpoint</code> · <code>google_network_security_firewall_endpoint_association</code> |
| [security-profiles.tf](./security-profiles.tf) | Organization-level network security profiles. |  | <code>google_network_security_security_profile</code> · <code>google_network_security_security_profile_group</code> |
| [tls-inspection.tf](./tls-inspection.tf) | TLS inspection policies and supporting resources. | <code>certificate-authority-service</code> | <code>google_certificate_manager_trust_config</code> · <code>google_network_security_tls_inspection_policy</code> |
| [variables-fast.tf](./variables-fast.tf) | FAST stage interface. |  |  |
| [variables.tf](./variables.tf) | Module variables. |  |  |

## Variables

| name | description | type | required | default | producer |
|---|---|:---:|:---:|:---:|:---:|
| [automation](variables-fast.tf#L19) | Automation resources created by the bootstrap stage. | <code title="object&#40;&#123;&#10;  outputs_bucket &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>0-bootstrap</code> |
| [ngfw_config](variables.tf#L93) | Configuration for NGFW Enterprise endpoints. Billing project defaults to the automation project. Network and TLS inspection policy ids support interpolation. | <code title="object&#40;&#123;&#10;  zones &#61; list&#40;string&#41;&#10;  name  &#61; optional&#40;string, &#34;ngfw-0&#34;&#41;&#10;  network_associations &#61; optional&#40;map&#40;object&#40;&#123;&#10;    vpc_id                &#61; string&#10;    disabled              &#61; optional&#40;bool&#41;&#10;    tls_inspection_policy &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |  |
| [organization](variables-fast.tf#L39) | Organization details. | <code title="object&#40;&#123;&#10;  domain      &#61; string&#10;  id          &#61; number&#10;  customer_id &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>00-globals</code> |
| [project_id](variables.tf#L113) | Project where the network security resources will be created. | <code>string</code> | ✓ |  |  |
| [certificate_authorities](variables.tf#L17) | Certificate Authority Service pool and CAs. If host project ids is null identical pools and CAs are created in every host project. | <code title="map&#40;object&#40;&#123;&#10;  location              &#61; string&#10;  iam                   &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings          &#61; optional&#40;map&#40;any&#41;, &#123;&#125;&#41;&#10;  iam_bindings_additive &#61; optional&#40;map&#40;any&#41;, &#123;&#125;&#41;&#10;  iam_by_principals     &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  ca_configs &#61; map&#40;object&#40;&#123;&#10;    deletion_protection                    &#61; optional&#40;string, true&#41;&#10;    type                                   &#61; optional&#40;string, &#34;SELF_SIGNED&#34;&#41;&#10;    is_ca                                  &#61; optional&#40;bool, true&#41;&#10;    lifetime                               &#61; optional&#40;string, null&#41;&#10;    pem_ca_certificate                     &#61; optional&#40;string, null&#41;&#10;    ignore_active_certificates_on_deletion &#61; optional&#40;bool, false&#41;&#10;    skip_grace_period                      &#61; optional&#40;bool, true&#41;&#10;    labels                                 &#61; optional&#40;map&#40;string&#41;, null&#41;&#10;    gcs_bucket                             &#61; optional&#40;string, null&#41;&#10;    key_spec &#61; optional&#40;object&#40;&#123;&#10;      algorithm  &#61; optional&#40;string, &#34;RSA_PKCS1_2048_SHA256&#34;&#41;&#10;      kms_key_id &#61; optional&#40;string, null&#41;&#10;    &#125;&#41;, &#123;&#125;&#41;&#10;    key_usage &#61; optional&#40;object&#40;&#123;&#10;      cert_sign          &#61; optional&#40;bool, true&#41;&#10;      client_auth        &#61; optional&#40;bool, false&#41;&#10;      code_signing       &#61; optional&#40;bool, false&#41;&#10;      content_commitment &#61; optional&#40;bool, false&#41;&#10;      crl_sign           &#61; optional&#40;bool, true&#41;&#10;      data_encipherment  &#61; optional&#40;bool, false&#41;&#10;      decipher_only      &#61; optional&#40;bool, false&#41;&#10;      digital_signature  &#61; optional&#40;bool, false&#41;&#10;      email_protection   &#61; optional&#40;bool, false&#41;&#10;      encipher_only      &#61; optional&#40;bool, false&#41;&#10;      key_agreement      &#61; optional&#40;bool, false&#41;&#10;      key_encipherment   &#61; optional&#40;bool, true&#41;&#10;      ocsp_signing       &#61; optional&#40;bool, false&#41;&#10;      server_auth        &#61; optional&#40;bool, true&#41;&#10;      time_stamping      &#61; optional&#40;bool, false&#41;&#10;    &#125;&#41;, &#123;&#125;&#41;&#10;    subject &#61; optional&#40;&#10;      object&#40;&#123;&#10;        common_name         &#61; string&#10;        organization        &#61; string&#10;        country_code        &#61; optional&#40;string&#41;&#10;        locality            &#61; optional&#40;string&#41;&#10;        organizational_unit &#61; optional&#40;string&#41;&#10;        postal_code         &#61; optional&#40;string&#41;&#10;        province            &#61; optional&#40;string&#41;&#10;        street_address      &#61; optional&#40;string&#41;&#10;      &#125;&#41;,&#10;      &#123;&#10;        common_name  &#61; &#34;test.example.com&#34;&#10;        organization &#61; &#34;Test Example&#34;&#10;      &#125;&#10;    &#41;&#10;    subject_alt_name &#61; optional&#40;object&#40;&#123;&#10;      dns_names       &#61; optional&#40;list&#40;string&#41;, null&#41;&#10;      email_addresses &#61; optional&#40;list&#40;string&#41;, null&#41;&#10;      ip_addresses    &#61; optional&#40;list&#40;string&#41;, null&#41;&#10;      uris            &#61; optional&#40;list&#40;string&#41;, null&#41;&#10;    &#125;&#41;, null&#41;&#10;    subordinate_config &#61; optional&#40;object&#40;&#123;&#10;      root_ca_id              &#61; optional&#40;string&#41;&#10;      pem_issuer_certificates &#61; optional&#40;list&#40;string&#41;&#41;&#10;    &#125;&#41;, null&#41;&#10;  &#125;&#41;&#41;&#10;  ca_pool_config &#61; object&#40;&#123;&#10;    ca_pool_id &#61; optional&#40;string, null&#41;&#10;    name       &#61; optional&#40;string, null&#41;&#10;    tier       &#61; optional&#40;string, &#34;DEVOPS&#34;&#41;&#10;  &#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [certificate_authority_pools](variables-fast.tf#L27) | Certificate authority pools. | <code title="map&#40;object&#40;&#123;&#10;  id       &#61; string&#10;  ca_ids   &#61; map&#40;string&#41;&#10;  location &#61; string&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> | <code>2-security</code> |
| [outputs_location](variables.tf#L107) | Path where providers and tfvars files for the following stages are written. Leave empty to disable. | <code>string</code> |  | <code>null</code> |  |
| [security_profiles](variables.tf#L119) | Security profile groups for Layer 7 inspection. Null environment list means all environments. | <code title="map&#40;object&#40;&#123;&#10;  description &#61; optional&#40;string&#41;&#10;  threat_prevention_profile &#61; optional&#40;object&#40;&#123;&#10;    severity_overrides &#61; optional&#40;map&#40;object&#40;&#123;&#10;      action   &#61; string&#10;      severity &#61; string&#10;    &#125;&#41;&#41;&#41;&#10;    threat_overrides &#61; optional&#40;map&#40;object&#40;&#123;&#10;      action    &#61; string&#10;      threat_id &#61; string&#10;    &#125;&#41;&#41;&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code title="&#123;&#10;  ngfw-default &#61; &#123;&#125;&#10;&#125;">&#123;&#8230;&#125;</code> |  |
| [tls_inspection_policies](variables.tf#L161) | TLS inspection policies configuration. CA pools, trust configs and host project ids support interpolation. | <code title="map&#40;object&#40;&#123;&#10;  ca_pool_id            &#61; string&#10;  location              &#61; string&#10;  exclude_public_ca_set &#61; optional&#40;bool&#41;&#10;  trust_config          &#61; optional&#40;string&#41;&#10;  tls &#61; optional&#40;object&#40;&#123;&#10;    custom_features &#61; optional&#40;list&#40;string&#41;&#41;&#10;    feature_profile &#61; optional&#40;string&#41;&#10;    min_version     &#61; optional&#40;string&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [trust_configs](variables.tf#L203) | Certificate Manager trust configurations for TLS inspection policies. Project ids and region can reference keys in the relevant FAST variables. | <code title="map&#40;object&#40;&#123;&#10;  location                 &#61; string&#10;  description              &#61; optional&#40;string&#41;&#10;  allowlisted_certificates &#61; optional&#40;map&#40;string&#41;&#41;&#10;  trust_stores &#61; optional&#40;map&#40;object&#40;&#123;&#10;    intermediate_cas &#61; optional&#40;map&#40;string&#41;&#41;&#10;    trust_anchors    &#61; optional&#40;map&#40;string&#41;&#41;&#10;  &#125;&#41;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code title="&#123;&#10;&#125;">&#123;&#8230;&#125;</code> |  |
| [vpc_self_links](variables-fast.tf#L49) | VPC network self links. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> | <code>2-networking</code> |
<!-- END TFDOC -->
