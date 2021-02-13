# Cloud Identity Group Module

This module allows creating a Cloud Identity group and assigning members.

## Usage
To use this module you must either run terraform as a user that has the Groups Admin role in Cloud Identity or [enable domain-wide delegation](https://developers.google.com/admin-sdk/directory/v1/guides/delegation) to the service account used by terraform. If you use a service account, you must also grant that service account the Groups Admin role in Cloud Identity.

Please note that the underlying terraform resources only allow the creation of groups with members that are part of the organization. If you want to create memberships for identities outside your own organization, you have to manually allow members outside your organization in the Cloud Identity admin console.

As of version 3.50 of the GCP Terraform provider two operations are not working:
- removing a group that has at least one OWNER managed by terraform ([bug](https://github.com/hashicorp/terraform-provider-google/issues/7617))
- removing a role from an existing membership ([bug](https://github.com/hashicorp/terraform-provider-google/issues/7616))

Until those two bugs are fixed, this module will only support the creation of MEMBER memberships.

## Examples

### Simple Group
```hcl
module "group" {
  source       = "./modules/cloud-identity-group"
  customer_id  = "customers/C01234567"
  name         = "mygroup@example.com"
  display_name = "My group name"
  description  = "My group Description"
  members = [
    "user1@example.com",
    "user2@example.com",
    "service-account@my-gcp-project.iam.gserviceaccount.com"
  ]
}
# tftest:modules=1:resources=4
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| customer_id | Directory customer ID in the form customers/C0xxxxxxx. | <code title="string&#10;validation &#123;&#10;condition     &#61; can&#40;regex&#40;&#34;&#94;customers&#47;C0&#91;a-z0-9&#93;&#123;7&#125;&#36;&#34;, var.customer_id&#41;&#41;&#10;error_message &#61; &#34;Customer ID must be in the form customers&#47;C0xxxxxxx.&#34;&#10;&#125;">string</code> | ✓ |  |
| display_name | Group display name. | <code title="">string</code> | ✓ |  |
| name | Group ID (usually an email). | <code title="">string</code> | ✓ |  |
| *description* | Group description | <code title="">string</code> |  | <code title="">null</code> |
| *members* | List of group members. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| id | Group ID. |  |
| name | Group name. |  |
<!-- END TFDOC -->
