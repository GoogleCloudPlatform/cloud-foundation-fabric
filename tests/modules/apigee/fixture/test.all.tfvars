project_id = "my-project"
organization = {
  display_name            = "My Organization"
  description             = "My Organization"
  authorized_network      = "my-vpc"
  runtime_type            = "CLOUD"
  billing_type            = "Pay-as-you-go"
  database_encryption_key = "123456789"
  analytics_region        = "europe-west1"
}
envgroups = {
  test = ["test.example.com"]
  prod = ["prod.example.com"]
}
environments = {
  apis-test = {
    display_name = "APIs test"
    description  = "APIs Test"
    envgroups    = ["test"]
  }
  apis-prod = {
    display_name = "APIs prod"
    description  = "APIs prod"
    envgroups    = ["prod"]
    iam = {
      "roles/viewer" = ["group:devops@myorg.com"]
    }
  }
}
instances = {
  instance-test-ew1 = {
    region            = "europe-west1"
    environments      = ["apis-test"]
    psa_ip_cidr_range = "10.0.4.0/22"
  }
  instance-prod-ew3 = {
    region            = "europe-west3"
    environments      = ["apis-prod"]
    psa_ip_cidr_range = "10.0.5.0/22"
  }
}
endpoint_attachments = {
  endpoint-backend-1 = {
    region             = "europe-west1"
    service_attachment = "projects/my-project-1/serviceAttachments/gkebackend1"
  }
  endpoint-backend-2 = {
    region             = "europe-west1"
    service_attachment = "projects/my-project-2/serviceAttachments/gkebackend2"
  }
}
