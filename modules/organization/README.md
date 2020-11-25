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
  iam = { "roles/projectCreator" = ["group:cloud-admins@example.org"] }
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
# tftest:modules=1:resources=4
```

## Hierarchical firewall rules
```hcl
module "org" {
  source = "./modules/organization"
  org_id = 11223344
  firewall_policies = {
    iap-policy = {
      allow-iap-ssh = {
        description = "Always allow ssh from IAP"
        direction   = "INGRESS"
        action      = "allow"
        priority    = 100
        ranges      = ["35.235.240.0/20"]
        ports = {
          tcp = ["22"]
        }
        target_service_accounts = null
        target_resources        = null
        logging                 = false
      }
    }
  }
  firewall_policy_attachments = {
    iap_policy = module.org.firewall_policy_id["iap-policy"]
  }
}
# tftest:modules=1:resources=3
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| organization_id | Organization id in organizations/nnnnnn format. | <code title="string&#10;validation &#123;&#10;condition     &#61; can&#40;regex&#40;&#34;&#94;organizations&#47;&#91;0-9&#93;&#43;&#34;, var.organization_id&#41;&#41;&#10;error_message &#61; &#34;The organization_id must in the form organizations&#47;nnn.&#34;&#10;&#125;">string</code> | ✓ |  |
| *custom_roles* | Map of role name => list of permissions to create in this project. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *firewall_policies* | Hierarchical firewall policies to *create* in the organization. | <code title="map&#40;map&#40;object&#40;&#123;&#10;description             &#61; string&#10;direction               &#61; string&#10;action                  &#61; string&#10;priority                &#61; number&#10;ranges                  &#61; list&#40;string&#41;&#10;ports                   &#61; map&#40;list&#40;string&#41;&#41;&#10;target_service_accounts &#61; list&#40;string&#41;&#10;target_resources        &#61; list&#40;string&#41;&#10;logging                 &#61; bool&#10;&#125;&#41;&#41;&#41;">map(map(object({...})))</code> |  | <code title="">{}</code> |
| *firewall_policy_attachments* | List of hierarchical firewall policy IDs to *attach* to the organization | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">{}</code> |
| *iam* | IAM bindings, in {ROLE => [MEMBERS]} format. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *iam_additive* | Non authoritative IAM bindings, in {ROLE => [MEMBERS]} format. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *iam_additive_members* | IAM additive bindings in {MEMBERS => [ROLE]} format. This might break if members are dynamic values. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *iam_audit_config* | Service audit logging configuration. Service as key, map of log permission (eg DATA_READ) and excluded members as value for each service. | <code title="map&#40;map&#40;list&#40;string&#41;&#41;&#41;">map(map(list(string)))</code> |  | <code title="">{}</code> |
| *policy_boolean* | Map of boolean org policies and enforcement value, set value to null for policy restore. | <code title="map&#40;bool&#41;">map(bool)</code> |  | <code title="">{}</code> |
| *policy_list* | Map of list org policies, status is true for allow, false for deny, null for restore. Values can only be used for allow or deny. | <code title="map&#40;object&#40;&#123;&#10;inherit_from_parent &#61; bool&#10;suggested_value     &#61; string&#10;status              &#61; bool&#10;values              &#61; list&#40;string&#41;&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| firewall_policies | Map of firewall policy resources created in the organization. |  |
| firewall_policy_id | Map of firewall policy ids created in the organization. |  |
| organization_id | Organization id dependent on module resources. |  |
<!-- END TFDOC -->
