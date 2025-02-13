# Secure Web Proxy Add-on

This add-on allows creating an arbitrary number of [Secure Web Proxy (SWP)](https://cloud.google.com/secure-web-proxy/docs/overview), including resources required to enable TLS inspection.

This diagram shows the resources used by this add-on, and their relationships with its networking parent stage.

<p align="center">
  <img src="diagram.png" alt="SWP add-on diagram">
</p>

<!-- BEGIN TOC -->
- [Design overview and choices](#design-overview-and-choices)
- [How to run this stage](#how-to-run-this-stage)
  - [Provider and Terraform variables](#provider-and-terraform-variables)
  - [Impersonating the automation service account](#impersonating-the-automation-service-account)
  - [Variable configuration](#variable-configuration)
  - [Running the stage](#running-the-stage)
- [Files](#files)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Design overview and choices

This add-on is intentionally self-contained to allow directly using it to implement different designs, via a single instance or multiple instances.

All project-level resources in this stage are created in the same project, so that dependencies and IAM configurations are kept as simple as possible, and everything is within the same span of control.

The controlling project is usually one of those already created and managed by the networking stage: the landing host project, or a shared environment project if that exists. Alternatively, a dedicated project can be created and used here provided the necessary IAM and organization policies configurations are also defined.

## How to run this stage

Once the main networking stage has been configured and applied, the following configuration is added the the resource management `fast_addon` variable to create the add-on provider files, and its optional CI/CD resources if those are also required. The add-on name (`networking-swp`) is customizable, in case the add-on needs to be run multiple times to create gateways in different projects.

```hcl
fast_addon = {
  networking-swp = {
    parent_stage = "2-networking"
    # cicd_config = {
    #   identity_provider = "github-test"
    #   repository = {
    #     name   = "test/swp"
    #     type   = "github"
    #     branch = "main"
    #   }
    # }
  }
}
```

### Provider and Terraform variables

As all other FAST stages, the [mechanism used to pass variable values and pre-built provider files from one stage to the next](../../stages/0-bootstrap/README.md#output-files-and-cross-stage-variables) is also leveraged here.

The commands to link or copy the provider and terraform variable files can be easily derived from the `fast-links.sh` script in the FAST stages folder, passing it a single argument with the local output files folder (if configured) or the GCS output bucket in the automation project (derived from stage 0 outputs). The following example uses local files but GCS behaves identically.

```bash
../../stages/fast-links.sh ~/fast-config
# File linking commands for Secure Web Proxy networking add-on

# provider file
ln -s ~/fast-config/providers/2-networking-swp-providers.tf ./

# input files from other stages
ln -s ~/fast-config/tfvars/0-globals.auto.tfvars.json ./
ln -s ~/fast-config/tfvars/0-bootstrap.auto.tfvars.json ./
ln -s ~/fast-config/tfvars/1-resman.auto.tfvars.json ./
ln -s ~/fast-config/tfvars/2-networking.auto.tfvars.json ./

# conventional place for stage tfvars (manually created)
ln -s ~/fast-config/2-networking-swp.auto.tfvars ./

# optional files
ln -s ~/fast-config/tfvars/2-security.auto.tfvars.json ./
```

### Impersonating the automation service account

The preconfigured provider file uses impersonation to run with this stage's automation service account's credentials. The `gcp-devops` and `organization-admins` groups have the necessary IAM bindings in place to do that, so make sure the current user is a member of one of those groups.

### Variable configuration

Variables in this stage -- like most other FAST stages -- are broadly divided into three separate sets:

- variables which refer to global values for the whole organization (org id, billing account id, prefix, etc.), which are pre-populated via the `0-globals.auto.tfvars.json` file linked or copied above
- variables which refer to resources managed by previous stages, which are prepopulated here via the `0-bootstrap.auto.tfvars.json`, `1-resman.auto.tfvars.json` and `2-networking.auto.tfvars.json` files linked or copied above
- and finally variables that optionally control this stage's behaviour and customizations, and can to be set in a custom `terraform.tfvars` file

The first two sets are defined in the `variables-fast.tf` file, the latter set in the `variables.tf` file. The full list of variables can be found in the [Variables](#variables) table at the bottom of this document.

Note that the `outputs_location` variable is disabled by default, you need to explicitly set it in your `terraform.tfvars` file if you want output files to be generated by this stage. This is a sample `terraform.tfvars` that configures it, refer to the [bootstrap stage documentation](../../stages/0-bootstrap/README.md#output-files-and-cross-stage-variables) for more details:

```tfvars
outputs_location = "~/fast-config"
```

Once output files are in place, define your addon configuration in a tfvars file. This is an example of configuring this addon, with optional variable attributes filled in for illustration purposes.

Note that project id and networking variables use interpolation from FAST, and refer to the aliased resource names for portability. This is of course optional, and full resource ids can be used instead if needed.

```hcl
certificate_authority = {
  ca_configs = {
    swp = {
      deletion_protection = false
      subject = {
        common_name  = "fast-test-00.joonix.net"
        organization = "FAST Test 00"
      }
    }
  }
}
locations = {
  pri = "primary"
}
outputs_location = "~/fast-config"
project_id       = "prod-landing"
swp_configs = {
  shared = {
    network_id    = "prod-landing"
    subnetwork_id = "net"
  }
  # any other option supported by the net-swp module can be used here
}
tls_inspection_policy = {
  exclude_public_ca_set = true
}
```

### Running the stage

Once provider and variable values are in place and the correct user is configured, the stage can be run:

```bash
terraform init
terraform apply
```

<!-- TFDOC OPTS files:1 show_extra:1 exclude:2-networking-swp-providers.tf -->
<!-- BEGIN TFDOC -->
## Files

| name | description | modules | resources |
|---|---|---|---|
| [main.tf](./main.tf) | Module-level locals and resources. | <code>net-swp</code> · <code>project</code> |  |
| [outputs.tf](./outputs.tf) | Module outputs. |  | <code>google_storage_bucket_object</code> · <code>local_file</code> |
| [tls-inspection.tf](./tls-inspection.tf) | TLS inspection policies and supporting resources. | <code>certificate-authority-service</code> | <code>google_network_security_tls_inspection_policy</code> |
| [variables-fast.tf](./variables-fast.tf) | FAST stage interface. |  |  |
| [variables.tf](./variables.tf) | Module variables. |  |  |

## Variables

| name | description | type | required | default | producer |
|---|---|:---:|:---:|:---:|:---:|
| [automation](variables-fast.tf#L28) | Automation resources created by the bootstrap stage. | <code title="object&#40;&#123;&#10;  outputs_bucket &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>0-bootstrap</code> |
| [certificate_authority](variables.tf#L17) | Optional Certificate Authority Service pool and CA used by SWP. | <code title="object&#40;&#123;&#10;  iam                   &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings          &#61; optional&#40;map&#40;any&#41;, &#123;&#125;&#41;&#10;  iam_bindings_additive &#61; optional&#40;map&#40;any&#41;, &#123;&#125;&#41;&#10;  iam_by_principals     &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  ca_configs &#61; map&#40;object&#40;&#123;&#10;    deletion_protection                    &#61; optional&#40;string, true&#41;&#10;    type                                   &#61; optional&#40;string, &#34;SELF_SIGNED&#34;&#41;&#10;    is_ca                                  &#61; optional&#40;bool, true&#41;&#10;    lifetime                               &#61; optional&#40;string, null&#41;&#10;    pem_ca_certificate                     &#61; optional&#40;string, null&#41;&#10;    ignore_active_certificates_on_deletion &#61; optional&#40;bool, false&#41;&#10;    skip_grace_period                      &#61; optional&#40;bool, true&#41;&#10;    labels                                 &#61; optional&#40;map&#40;string&#41;, null&#41;&#10;    gcs_bucket                             &#61; optional&#40;string, null&#41;&#10;    key_spec &#61; optional&#40;object&#40;&#123;&#10;      algorithm  &#61; optional&#40;string, &#34;RSA_PKCS1_2048_SHA256&#34;&#41;&#10;      kms_key_id &#61; optional&#40;string, null&#41;&#10;    &#125;&#41;, &#123;&#125;&#41;&#10;    key_usage &#61; optional&#40;object&#40;&#123;&#10;      cert_sign          &#61; optional&#40;bool, true&#41;&#10;      client_auth        &#61; optional&#40;bool, false&#41;&#10;      code_signing       &#61; optional&#40;bool, false&#41;&#10;      content_commitment &#61; optional&#40;bool, false&#41;&#10;      crl_sign           &#61; optional&#40;bool, true&#41;&#10;      data_encipherment  &#61; optional&#40;bool, false&#41;&#10;      decipher_only      &#61; optional&#40;bool, false&#41;&#10;      digital_signature  &#61; optional&#40;bool, false&#41;&#10;      email_protection   &#61; optional&#40;bool, false&#41;&#10;      encipher_only      &#61; optional&#40;bool, false&#41;&#10;      key_agreement      &#61; optional&#40;bool, false&#41;&#10;      key_encipherment   &#61; optional&#40;bool, true&#41;&#10;      ocsp_signing       &#61; optional&#40;bool, false&#41;&#10;      server_auth        &#61; optional&#40;bool, true&#41;&#10;      time_stamping      &#61; optional&#40;bool, false&#41;&#10;    &#125;&#41;, &#123;&#125;&#41;&#10;    subject &#61; optional&#40;&#10;      object&#40;&#123;&#10;        common_name         &#61; string&#10;        organization        &#61; string&#10;        country_code        &#61; optional&#40;string&#41;&#10;        locality            &#61; optional&#40;string&#41;&#10;        organizational_unit &#61; optional&#40;string&#41;&#10;        postal_code         &#61; optional&#40;string&#41;&#10;        province            &#61; optional&#40;string&#41;&#10;        street_address      &#61; optional&#40;string&#41;&#10;      &#125;&#41;,&#10;      &#123;&#10;        common_name  &#61; &#34;test.example.com&#34;&#10;        organization &#61; &#34;Test Example&#34;&#10;      &#125;&#10;    &#41;&#10;    subject_alt_name &#61; optional&#40;object&#40;&#123;&#10;      dns_names       &#61; optional&#40;list&#40;string&#41;, null&#41;&#10;      email_addresses &#61; optional&#40;list&#40;string&#41;, null&#41;&#10;      ip_addresses    &#61; optional&#40;list&#40;string&#41;, null&#41;&#10;      uris            &#61; optional&#40;list&#40;string&#41;, null&#41;&#10;    &#125;&#41;, null&#41;&#10;    subordinate_config &#61; optional&#40;object&#40;&#123;&#10;      root_ca_id              &#61; optional&#40;string&#41;&#10;      pem_issuer_certificates &#61; optional&#40;list&#40;string&#41;&#41;&#10;    &#125;&#41;, null&#41;&#10;  &#125;&#41;&#41;&#10;  ca_pool_config &#61; optional&#40;object&#40;&#123;&#10;    create_pool &#61; optional&#40;object&#40;&#123;&#10;      name &#61; optional&#40;string&#41;&#10;      tier &#61; optional&#40;string, &#34;DEVOPS&#34;&#41;&#10;    &#125;&#41;&#41;&#10;    use_pool &#61; optional&#40;object&#40;&#123;&#10;      id &#61; string&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |  |
| [project_id](variables.tf#L143) | Project where the resources will be created. | <code>string</code> | ✓ |  |  |
| [_fast_debug](variables-fast.tf#L19) | Internal FAST variable used for testing and debugging. Do not use. | <code title="object&#40;&#123;&#10;  skip_datasources &#61; optional&#40;bool, false&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [enable_services](variables.tf#L95) | Configure project by enabling services required for this add-on. | <code>bool</code> |  | <code>false</code> |  |
| [factories_config](variables.tf#L102) | SWP factories configuration paths. Keys in the `swp_configs` variable will be appended to derive individual SWP factory paths. | <code title="object&#40;&#123;&#10;  policy_rules &#61; optional&#40;string, &#34;data&#47;policy-rules&#34;&#41;&#10;  url_lists    &#61; optional&#40;string, &#34;data&#47;url-lists&#34;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [host_project_ids](variables-fast.tf#L36) | Networking stage host project id aliases. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> | <code>2-networking</code> |
| [locations](variables.tf#L112) | Regions where the resources will be created. Keys are used as short names appended to resource names. Interpolation with FAST region names is supported. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [name](variables.tf#L119) | Name used for resource names. | <code>string</code> |  | <code>&#34;swp&#34;</code> |  |
| [outputs_location](variables.tf#L126) | Path where providers and tfvars files for the following stages are written. Leave empty to disable. | <code>string</code> |  | <code>null</code> |  |
| [policy_rules_contexts](variables.tf#L132) | Replacement contexts for policy rules matcher arguments. | <code title="object&#40;&#123;&#10;  secure_tags      &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  service_accounts &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  url_lists        &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [regions](variables-fast.tf#L44) | Networking stage region aliases. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> | <code>2-networking</code> |
| [subnet_self_links](variables-fast.tf#L52) | VPC subnetwork self links. | <code>map&#40;map&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> | <code>2-networking</code> |
| [swp_configs](variables.tf#L149) | Secure Web Proxy configuration, one per region. | <code title="map&#40;object&#40;&#123;&#10;  network_id               &#61; string&#10;  subnetwork_id            &#61; string&#10;  certificates             &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  tls_inspection_policy_id &#61; optional&#40;string, null&#41;&#10;  gateway_config &#61; optional&#40;object&#40;&#123;&#10;    addresses                &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    delete_router_on_destroy &#61; optional&#40;bool, true&#41;&#10;    labels                   &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;    next_hop_routing_mode    &#61; optional&#40;bool, false&#41;&#10;    ports                    &#61; optional&#40;list&#40;string&#41;, &#91;443&#93;&#41;&#10;    scope                    &#61; optional&#40;string&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  service_attachment &#61; optional&#40;object&#40;&#123;&#10;    nat_subnets           &#61; list&#40;string&#41;&#10;    automatic_connection  &#61; optional&#40;bool, false&#41;&#10;    consumer_accept_lists &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;    consumer_reject_lists &#61; optional&#40;list&#40;string&#41;&#41;&#10;    description           &#61; optional&#40;string&#41;&#10;    domain_name           &#61; optional&#40;string&#41;&#10;    enable_proxy_protocol &#61; optional&#40;bool, false&#41;&#10;    reconcile_connections &#61; optional&#40;bool&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [tls_inspection_policy](variables.tf#L179) | TLS inspection policy configuration. If a CA pool is not specified a local one must be created via the `certificate_authority` variable. | <code title="object&#40;&#123;&#10;  ca_pool_id            &#61; optional&#40;string&#41;&#10;  exclude_public_ca_set &#61; optional&#40;bool&#41;&#10;  tls &#61; optional&#40;object&#40;&#123;&#10;    custom_features &#61; optional&#40;list&#40;string&#41;&#41;&#10;    feature_profile &#61; optional&#40;string&#41;&#10;    min_version     &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |  |
| [vpc_self_links](variables-fast.tf#L60) | VPC network self links. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> | <code>2-networking</code> |

## Outputs

| name | description | sensitive | consumers |
|---|---|:---:|---|
| [cas_pool_ids](outputs.tf#L34) | Certificate Authority Service pool ids. |  |  |
| [gateway_security_policies](outputs.tf#L39) | The gateway security policy resources. |  |  |
| [gateways](outputs.tf#L44) | The gateway resources. |  |  |
| [ids](outputs.tf#L49) | Gateway IDs. |  |  |
| [service_attachments](outputs.tf#L54) | Service attachment IDs. |  |  |
<!-- END TFDOC -->
