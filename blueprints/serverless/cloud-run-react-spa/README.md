# React single page app on Cloud Run + Cloud Storage

## Introduction

This blueprint contains a simple React single page application created with [`create-react-app`](https://create-react-app.dev/)
and necessary Terraform resources to deploy it in on Google Cloud. The blueprint also contains a very simple Python backend
that returns `Hello World`.

## Prerequisites

You will need an existing [project](https://cloud.google.com/resource-manager/docs/creating-managing-projects) with [billing enabled](https://cloud.google.com/billing/docs/how-to/modify-project) and a user with the “Project owner” [IAM](https://cloud.google.com/iam) role on that project. __Note__: to grant a user a role, take a look at the [Granting and Revoking Access](https://cloud.google.com/iam/docs/granting-changing-revoking-access#grant-single-role) documentation.

## Spinning up the architecture

### General steps

1. Clone the repo to your local machine or Cloud Shell:

```bash
git clone https://github.com/GoogleCloudPlatform/cloud-foundation-fabric
```

2. Change to the directory of the blueprint:

```bash
cd cloud-foundation-fabric/blueprints/serverless/cloud-run-react-spa
```

You should see this README and some terraform files.

3. To deploy a specific use case, you will need to create a file in this directory called `terraform.tfvars` and follow the corresponding instructions to set variables. Values that are meant to be substituted will be shown inside brackets but you need to omit these brackets. E.g.:

```tfvars
project_id = "[your-project_id]"
region="[region-to-deploy-in]"
```

may become

```tfvars
project_id="my-project-id"
region="europe-west4"
```

Although each use case is somehow built around the previous one they are self-contained so you can deploy any of them at will.

4. Now, you should build the React application:

```sh
# cd my-app
# npm install
# npm run build
# cd..
```

5. The usual terraform commands will do the work:

```bash
terraform init
terraform plan
terraform apply
```

It will take a few minutes. When complete, you should see an output stating the command completed successfully, a list of the created resources, and some output variables with information to access your services.

__Congratulations!__ You have successfully deployed the use case you chose based on the variables configuration.

### Deploy regional load balancer

You can choose between global and regional load balancer (or use both) by setting `regional_lb` and `global_lb` variables in
your `terraform.tfvars`.
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [project_id](variables.tf#L52) | Google Cloud project ID | <code>string</code> | ✓ |  |
| [region](variables.tf#L66) | Region where to deploy the function and resources | <code>string</code> | ✓ |  |
| [backend](variables.tf#L25) | Backend settings | <code title="object&#40;&#123;&#10;  function_name   &#61; optional&#40;string, &#34;my-react-app-backend&#34;&#41;&#10;  service_account &#61; optional&#40;string, &#34;my-react-app-backend&#34;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [bucket](variables.tf#L15) | Bucket settings for hosting the SPA | <code title="object&#40;&#123;&#10;  name          &#61; optional&#40;string, &#34;my-react-app&#34;&#41;&#10;  random_suffix &#61; optional&#40;bool, true&#41;&#10;  build_name    &#61; optional&#40;string, &#34;my-react-app-build&#34;&#41; &#35; Build bucket for CF v2&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [global_lb](variables.tf#L34) | Deploy a global load balancer | <code>bool</code> |  | <code>true</code> |
| [lb_name](variables.tf#L40) | Application Load Balancer name | <code>string</code> |  | <code>&#34;my-react-app&#34;</code> |
| [nginx_image](variables.tf#L46) | Nginx image to use for regional load balancer | <code>string</code> |  | <code>&#34;gcr.io&#47;cloud-marketplace&#47;google&#47;nginx1:1.26&#34;</code> |
| [project_create](variables.tf#L57) | Parameters for the creation of a new project. | <code title="object&#40;&#123;&#10;  billing_account_id &#61; string&#10;  parent             &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [regional_lb](variables.tf#L71) | Deploy a regional load balancer | <code>bool</code> |  | <code>false</code> |
| [vpc_config](variables.tf#L77) | Settings for VPC (required when deploying a Regional XLB) | <code title="object&#40;&#123;&#10;  network                &#61; string&#10;  network_project        &#61; optional&#40;string&#41;&#10;  subnetwork             &#61; string&#10;  subnet_cidr            &#61; optional&#40;string, &#34;172.20.20.0&#47;24&#34;&#41;&#10;  proxy_only_subnetwork  &#61; string&#10;  proxy_only_subnet_cidr &#61; optional&#40;string, &#34;172.20.30.0&#47;24&#34;&#41;&#10;  create                 &#61; optional&#40;bool, true&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  network               &#61; &#34;my-react-app-vpc&#34;&#10;  subnetwork            &#61; &#34;my-react-app-vpc-subnet&#34;&#10;  proxy_only_subnetwork &#61; &#34;my-react-app-vpc-proxy-subnet&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [global_lb](outputs.tf#L15) | Global load balancer address |  |
| [regional_lb](outputs.tf#L20) | Regional load balancer address |  |
<!-- END TFDOC -->
