module "test-vm" {
  source        = "../../../modules/compute-vm"
  project_id    = module.gke-project-0.project_id
  zone          = "europe-west1-b"
  name          = "test-vm"
  instance_type = "n2d-standard-2"
  encryption = {
    kms_key_self_link = var.compute_kms_key
  }
  confidential_compute = true
  shielded_config = {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }
  boot_disk = {
    initialize_params = {
      image = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2204-lts"
    }
  }
  network_interfaces = [{
    network    = var.vpc_self_links["dev"]
    subnetwork = var.subnet_self_links["dev"]["europe-west1/dev-default"]
  }]
  service_account = {
    auto_create = false
    email       = var.compute_service_account
  }
  metadata = {
    block-project-ssh-keys = "TRUE"
  }
  tags = ["ssh"]
}
