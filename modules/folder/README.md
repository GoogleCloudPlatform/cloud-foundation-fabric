# Google Cloud Folder Module

This module allows the creation and management of folders together with their individual IAM bindings and organization policies.

## Examples

### IAM bindings

```hcl
module "folder" {
  source = "./modules/folder"
  parent = "organizations/1234567890"
  name  = "Folder name"
  iam = {
    "roles/owner" = ["group:users@example.com"]
  }
}
```

### Organization policies

```hcl
module "folder" {
  source = "./modules/folder"
  parent = "organizations/1234567890"
  name  = "Folder name"
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
| name | Folder name. | <code title="">string</code> | ✓ |  |
| parent | Parent in folders/folder_id or organizations/org_id format. | <code title="string&#10;validation &#123;&#10;condition     &#61; can&#40;regex&#40;&#34;&#40;organizations&#124;folders&#41;&#47;&#91;0-9&#93;&#43;&#34;, var.parent&#41;&#41;&#10;error_message &#61; &#34;Parent must be of the form folders&#47;folder_id or organizations&#47;organization_id.&#34;&#10;&#125;">string</code> | ✓ |  |
| *iam* | IAM bindings in {ROLE => [MEMBERS]} format. | <code title="map&#40;set&#40;string&#41;&#41;">map(set(string))</code> |  | <code title="">{}</code> |
| *policy_boolean* | Map of boolean org policies and enforcement value, set value to null for policy restore. | <code title="map&#40;bool&#41;">map(bool)</code> |  | <code title="">{}</code> |
| *policy_list* | Map of list org policies, status is true for allow, false for deny, null for restore. Values can only be used for allow or deny. | <code title="map&#40;object&#40;&#123;&#10;inherit_from_parent &#61; bool&#10;suggested_value     &#61; string&#10;status              &#61; bool&#10;values              &#61; list&#40;string&#41;&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| folder | Folder resource. |  |
| id | Folder id. |  |
| name | Folder name. |  |
<!-- END TFDOC -->
