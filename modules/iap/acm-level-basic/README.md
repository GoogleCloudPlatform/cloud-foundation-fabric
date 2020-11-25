
# Access Context Manager basic

This module allows to create policies in the (GCP Access Context Manager)[https://cloud.google.com/access-context-manager/docs] in an easy way. It makes use of the (google_access_context_manager_access_level)[https://www.terraform.io/docs/providers/google/r/access_context_manager_access_level.html] Terraform resource.


## Example of usage

```terraform
module "" {
    device_policies = {
        "my bool" = true
    }
    ip_ranges = ["10.0.0.0/8"]
    members = ["user:admin@domain.com"]
    policy = "my policy"
    title = "my title"
}
```