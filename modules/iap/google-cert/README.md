
# Googe certificate

This module creates an ssl certificate and an ip independently. It provides the name of the certificate as output.


## Example of usage

```terraform
module "google-cert" {
    source     = "./modules/iap/google-cert"
    project_id = "project-id"
    name       = "example-com"
    domains    = ["example.com"]
}
```