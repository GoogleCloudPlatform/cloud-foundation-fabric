
# Google brand

It makes use of the (google_iap_brand)[https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iap_brand] and optionally the (google_iap_client)[https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iap_brand] Terraform resource. It provides the `client_id` and `client_secret` as output.


## Example of usage

```terraform
module "iap-brand" {
    source            = "./modules/iap/iap-brand"
    project_id        = "project-id"
    application_title = "Title of the application"
    client_name       = "Client name"
    create_client     = true
    # group or user must exist in Cloud Identity
    support_email     = "support@example.com"
}
