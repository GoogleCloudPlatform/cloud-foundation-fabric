# Apigee X - Northbound: External Application LB with PSC Neg, Southbouth: PSC with Internal Application LB and Hybrid NEG

The following blueprint shows how to expose an on-prem target backend to clients in the Internet.

The architecture is the one depicted below.

![Diagram](diagram.png)

To emulate an service deployed on-premise, we have used a managed instance group of instances running Nginx exposed via a regional internalload balancer (L7). The service is accessible through VPN.

## Running the blueprint

1. Clone this repository or [open it in cloud shell](https://ssh.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https%3A%2F%2Fgithub.com%2Fterraform-google-modules%2Fcloud-foundation-fabric&cloudshell_print=cloud-shell-readme.txt&cloudshell_working_dir=blueprints%2F%apigee%2F/network-patterns/nb-glb-psc-neg-sb-psc-ilbl7-hybrid-neg), then go through the following steps to create resources:

2. Copy the file [terraform.tfvars.sample](./terraform.tfvars.sample) to a file called ```terraform.tfvars``` and update the values if required.

3. Initialize the terraform configuration

    ```terraform init```

4. Apply the terraform configuration

    ```terraform apply```

Once the resources have been created, do the following:

Create an A record in your DNS registrar to point the environment group hostname to the public IP address returned after the terraform configuration was applied. You might need to wait some time until the certificate is provisioned.

## Testing the blueprint

Do the following to verify that everything works as expected.

1. Deploy the API proxy

        ./deploy-apiproxy.sh

2. Send a request

        curl -v https://HOSTNAME/test/

    You should get back an HTTP 200 OK response.
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [apigee_project_id](variables.tf#L17) | Project ID. | <code>string</code> | ✓ |  |
| [billing_account_id](variables.tf#L53) | Parameters for the creation of the new project. | <code>string</code> | ✓ |  |
| [hostname](variables.tf#L58) | Host name. | <code>string</code> | ✓ |  |
| [onprem_project_id](variables.tf#L63) | Project ID. | <code>string</code> | ✓ |  |
| [parent](variables.tf#L81) | Parent (organizations/organizationID or folders/folderID). | <code>string</code> | ✓ |  |
| [apigee_proxy_only_subnet_ip_cidr_range](variables.tf#L23) | Subnet IP CIDR range. | <code>string</code> |  | <code>&#34;10.2.1.0&#47;24&#34;</code> |
| [apigee_psc_subnet_ip_cidr_range](variables.tf#L29) | Subnet IP CIDR range. | <code>string</code> |  | <code>&#34;10.2.2.0&#47;24&#34;</code> |
| [apigee_runtime_ip_cidr_range](variables.tf#L35) | Apigee PSA IP CIDR range. | <code>string</code> |  | <code>&#34;10.0.4.0&#47;22&#34;</code> |
| [apigee_subnet_ip_cidr_range](variables.tf#L41) | Subnet IP CIDR range. | <code>string</code> |  | <code>&#34;10.2.0.0&#47;24&#34;</code> |
| [apigee_troubleshooting_ip_cidr_range](variables.tf#L47) | Apigee PSA IP CIDR range. | <code>string</code> |  | <code>&#34;10.1.0.0&#47;28&#34;</code> |
| [onprem_proxy_only_subnet_ip_cidr_range](variables.tf#L69) | Subnet IP CIDR range. | <code>string</code> |  | <code>&#34;10.1.1.0&#47;24&#34;</code> |
| [onprem_subnet_ip_cidr_range](variables.tf#L75) | Subnet IP CIDR range. | <code>string</code> |  | <code>&#34;10.1.0.0&#47;24&#34;</code> |
| [region](variables.tf#L86) | Region. | <code>string</code> |  | <code>&#34;europe-west1&#34;</code> |
| [zone](variables.tf#L92) | Zone. | <code>string</code> |  | <code>&#34;europe-west1-c&#34;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [ip_address](outputs.tf#L17) | GLB IP address. |  |

<!-- END TFDOC -->

## Test

```hcl
module "test" {
  source             = "./fabric/blueprints/apigee/network-patterns/nb-glb-psc-neg-sb-psc-ilbl7-hybrid-neg"
  billing_account_id = "12345-12345-12345"
  parent             = "folders/123456789"
  apigee_project_id  = "my-apigee-project"
  onprem_project_id  = "my-onprem-project"
  hostname           = "test.myorg.org"
}
# tftest modules=14 resources=80
```
