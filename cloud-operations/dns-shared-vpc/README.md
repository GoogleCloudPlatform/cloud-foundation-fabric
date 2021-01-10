# Cloud DNS & Shared VPC design

## Usage

This Terraform module allows you to create reusable and modular Cloud DNS architectures when using Shared VPC.
The goal is to provision dedicated Cloud DNS instances for application teams that want to manage their own DNS records and configure DNS peering to ensure name resolution works in the Shared VPC.

This module will:
* Create a GCP project per application team (based on the teams list in variables.tf)
* Create a VPC and Cloud DNS instance per application team
* Create a Cloud DNS private zone per application team in the form of `[teamname].[dns_domain]`, with `teamname` and `dns_domain` being set in the inputs (see next section of this README)
* Configure DNS peering for each private zone from the Shared VPC to the DNS VPC of each application team

Note that Terraform 0.13 at least is required due to the use of for_each with modules.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| billing\_account | Billing account associated with the GCP Projects that will be created for each team | string | n/a | yes |
| dns\_domain | DNS domain under which each application team DNS domain will be created | string | n/a | yes |
| folder\_id | Folder ID in which projects will be created | string | n/a | yes |
| prefix | Customer name to use as prefix for resources' naming | string | `"test-dns"` | no |
| project\_services | Service APIs enabled by default | list of string | `["compute.googleapis.com", "dns.googleapis.com",]` | no |
| shared\_vpc\_link | Shared VPC self link, used for DNS peering | string | n/a | yes |
| teams | List of application teams requiring their own Cloud DNS instance | list of string | `["team1", "team2",]` | no |