# Playground folder module

Simple module to create a playground folder, and grant all relevant permissions on the correct resources (folder, billing account, organization) to enable specific identities to have complete control under it.

Special considerations

- setting Shared VPC Admin roles at the folder level is buggy and not guaranteed to work, ideally those should be set at the organization level
- if administrators should manage any project under the folder regardless of the identity that created them, the extra role `roles/owner` has to be added to the `folder_roles` variable; testing different levels of access will then require extra identities
- users from outside the org need the extra role `roles/browser` in the `organization_roles` variable

To retrofit the module after creation, just import an existing folder and apply.

## Example

```hcl
module "playground-demo" {
  source          = "./playground"
  administrators  = ["user:user1@example.com", "group:group1@example.com"]
  billing_account = "0123ABC-0123ABC-0123ABC"
  name            = "Playground test"
  organization_id = 1234567890
  parent          = "folders/1234567890"
}
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| billing_account | Billing account id on which ot assign billing roles. | <code title="">string</code> | ✓ |  |
| name | Playground folder name. | <code title="">string</code> | ✓ |  |
| organization_id | Top-level organization id on which to apply roles, format is the numeric id. | <code title="">number</code> | ✓ |  |
| parent | Parent organization or folder, in organizations/nnn or folders/nnn format. | <code title="">string</code> | ✓ |  |
| *administrators* | List of IAM-style identities that will manage the playground. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |
| *billing_roles* | List of IAM roles granted to administrators on the billing account. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="&#91;&#10;&#34;roles&#47;billing.user&#34;&#10;&#93;">...</code> |
| *folder_roles* | List of IAM roles granted to administrators on folder. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="&#91;&#10;&#34;roles&#47;resourcemanager.folderAdmin&#34;,&#10;&#34;roles&#47;resourcemanager.projectCreator&#34;,&#10;&#34;roles&#47;resourcemanager.projectIamAdmin&#34;,&#10;&#34;roles&#47;compute.xpnAdmin&#34;&#10;&#93;">...</code> |
| *organization_roles* | List of IAM roles granted to administrators on the organization. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="&#91;&#10;&#34;roles&#47;browser&#34;,&#10;&#34;roles&#47;resourcemanager.organizationViewer&#34;&#10;&#93;">...</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| folder | Folder resource. |  |
| folder_name | Folder name. |  |
<!-- END TFDOC -->
