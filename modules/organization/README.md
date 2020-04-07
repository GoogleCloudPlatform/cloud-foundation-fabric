# Organization Module

This module allows managing several organization properties:

- IAM bindings, both authoritative and additive
- custom IAM roles
- audit logging configuration for services
- organization policies

## Example

```hcl
module "org" {
  source      = "./modules/organization"
  org_id      = 1234567890
  iam_roles   = ["roles/projectCreator"]
  iam_members = { "roles/projectCreator" = ["group:cloud-admins@example.org"] }
  policy_boolean = {
    "constraints/compute.disableGuestAttributesAccess" = true
    "constraints/compute.skipDefaultNetworkCreation" = true
  }
  policy_list = {
    "constraints/compute.trustedImageProjects" = {
      inherit_from_parent = null
      suggested_value = null
      status = true
      values = ["projects/my-project"]
    }
  }
}
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| org_id | Organization id in nnnnnn format. | <code title="">number</code> | ✓ |  |
| *custom_roles* | Map of role name => list of permissions to create in this project. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *iam_additive_members* | Map of member lists used to set non authoritative bindings, keyed by role. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *iam_additive_roles* | List of roles used to set non authoritative bindings. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |
| *iam_audit_config* | Service audit logging configuration. Service as key, map of log permission (eg DATA_READ) and excluded members as value for each service. | <code title="map&#40;map&#40;list&#40;string&#41;&#41;&#41;">map(map(list(string)))</code> |  | <code title="">{}</code> |
| *iam_members* | Map of member lists used to set authoritative bindings, keyed by role. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *iam_roles* | List of roles used to set authoritative bindings. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |
| *policy_boolean* | Map of boolean org policies and enforcement value, set value to null for policy restore. | <code title="map&#40;bool&#41;">map(bool)</code> |  | <code title="">{}</code> |
| *policy_list* | Map of list org policies, status is true for allow, false for deny, null for restore. Values can only be used for allow or deny. | <code title="map&#40;object&#40;&#123;&#10;inherit_from_parent &#61; bool&#10;suggested_value     &#61; string&#10;status              &#61; bool&#10;values              &#61; list&#40;string&#41;&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| org_id | Organization id dependent on module resources. |  |
<!-- END TFDOC -->
