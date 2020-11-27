
# Access Context Manager basic

This module allows to create policies in the (GCP Access Context Manager)[https://cloud.google.com/access-context-manager/docs] in an easy way. It makes use of the (google_access_context_manager_access_level)[https://www.terraform.io/docs/providers/google/r/access_context_manager_access_level.html] Terraform resource. It provides the title of the access level as output.


## Example of usage

```terraform
module "acm-level-basic" {
    source          = "./modules/iap/acm-level-basic"
    device_policies = {
        # user device needs to be approved by an admin
        "require_admin_approval" = true,
        # user device needs to be corp owned.
        "require_corp_owned" = true
    }
    # access policy allows the following source addresses
    ip_ranges      = ["10.0.0.0/8"]
    members        = ["user:admin@domain.com"]
    policy         = "Parent policy id"
    title          = "Title of the access level"
}
```