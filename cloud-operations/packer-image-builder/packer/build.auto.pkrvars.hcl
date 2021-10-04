# Packer variables file template.
# Used by Terraform to generate Packer variable file.
project_id         = "mstefaniak-service"
compute_zone       = "europe-central2-a"
builder_sa         = "image-builder@mstefaniak-service.iam.gserviceaccount.com"
compute_sa         = "image-builder-vm@mstefaniak-service.iam.gserviceaccount.com"
compute_subnetwork = "image-builder"
use_iap            = true