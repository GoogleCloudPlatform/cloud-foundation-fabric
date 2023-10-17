# Dialogflow CX - Private deployment

## Tagline

Create a [Dialgoflow CX agent](https://cloud.google.com/dialogflow/cx/docs/concept/agent) with private connectivity to a Cloud Run instance acting as webhook.

## Detailed

This example implements the infrastructure required to deploy a [Dialgoflow CX agent](https://cloud.google.com/dialogflow/cx/docs/concept/agent) with private connectivity to a Cloud Run instance acting as webhook.

## Architecture

The blueprint will deploy all the required resources to have a fully functional Dialoglfow CX agent:

![Dialogflow CX private deployment architecure](./images/diagram.png "Dialogflow CX private deployment architecure")

## How to run this script

To deploy this blueprint on your GCP organization, you will need

- a folder or organization where new projects will be created
- a billing account that will be associated with the new projects

The solution is meant to be executed by a Service Account (or a regular user) having this minimal set of permission:

- **Billing account**
  - `roles/billing.user`
- **Folder level**:
  - `roles/resourcemanager.projectCreator`
- **Shared VPC host project** (if configured):\
  - `roles/compute.xpnAdmin` on the host project folder or org
  - `roles/resourcemanager.projectIamAdmin` on the host project, either with no conditions or with a condition allowing [delegated role grants](https://medium.com/google-cloud/managing-gcp-service-usage-through-delegated-role-grants-a843610f2226#:~:text=Delegated%20role%20grants%20is%20a,setIamPolicy%20permission%20on%20a%20resource.) for `roles/compute.networkUser`, `roles/composer.sharedVpcAgent`, `roles/container.hostServiceAgentUser`

## Variable configuration

There are a minimum set of variables you will need to fill in:

```tfvars
prefix = "test-1"

project_config = {
  billing_account_id = "01234E-E1234E-01234E"
  parent             = "folders/112233445566"
}

```

## Customization

### Virtual Private Cloud (VPC) design

As is often the case in real-world configurations, this blueprint accepts as input an existing [Shared-VPC](https://cloud.google.com/vpc/docs/shared-vpc) via the `network_config` variable.
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [prefix](variables.tf#L38) | Prefix used for resource names. | <code>string</code> | ✓ |  |
| [project_config](variables.tf#L47) | Provide 'billing_account_id' value if project creation is needed, uses existing 'project_id' if null. Parent is in 'folders/nnn' or 'organizations/nnn' format. | <code title="object&#40;&#123;&#10;  billing_account_id &#61; optional&#40;string&#41;&#10;  parent             &#61; string&#10;  project_id         &#61; optional&#40;string, &#34;df-cx&#34;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [language](variables.tf#L17) | Dialgogflow CX agent language. | <code>string</code> |  | <code>&#34;it&#34;</code> |
| [network_config](variables.tf#L23) | Shared VPC network configurations to use. If null network will be created in project. | <code title="object&#40;&#123;&#10;  host_project      &#61; optional&#40;string&#41;&#10;  network_self_link &#61; optional&#40;string&#41;&#10;  subnets_self_link &#61; optional&#40;object&#40;&#123;&#10;    service   &#61; string&#10;    proxy     &#61; string&#10;    connector &#61; string&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [region](variables.tf#L60) | Region used for regional resources. | <code>string</code> |  | <code>&#34;europe-west1&#34;</code> |
| [webhook_config](variables.tf#L66) | Container image to deploy. | <code title="object&#40;&#123;&#10;  image    &#61; optional&#40;string&#41;&#10;  url_path &#61; optional&#40;string, &#34;handle_webhook&#34;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [cx_agent_id](outputs.tf#L17) | Dialoglfow CX agent id. |  |
| [project](outputs.tf#L22) | GCP Project information. |  |
| [webhook](outputs.tf#L30) | Webhook information. |  |
<!-- END TFDOC -->
## Test

```hcl
module "test" {
  source = "./fabric/blueprints/ml-solutions/dialogflow-cx/"
  prefix = "pref-dev"
  project_config = {
    billing_account_id = "000000-123456-123456"
    parent             = "folders/111111111111"
    project_id         = "test-dev"
  }
}
# tftest modules=8 resources=51
```
