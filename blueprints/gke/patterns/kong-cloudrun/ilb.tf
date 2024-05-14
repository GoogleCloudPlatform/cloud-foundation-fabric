module "ilb-l7" {
  source     = "../../../../modules/net-lb-app-int"
  project_id = var.project_id
  name       = "ilb-l7-cr"
  region     = var.region
  backend_service_configs = {
    default = {
      project_id = module.service-project.project_id
      backends = [{
        group = "cr"
      }]
      health_checks = []
    }
    /* svc-1 = {
      project_id = module.service-project["service-project-1"].project_id
      backends = [{
        group = "cr1"
      }]
      health_checks = []
    }
    svc-2 = {
      project_id = module.service-project["service-project-2"].project_id
      backends = [{
        group = "cr2"
      }]
      health_checks = []
    } */
  }
  health_check_configs = {}
  neg_configs = {
    cr = {
      project_id = module.service-project.project_id
      cloudrun = {
        region = var.region
        target_service = {
          name = var.cloudrun_svcname
        }
      }
    }
  }
  protocol = "HTTPS"
  ssl_certificates = {
    create_configs = {
      default = {
        certificate = google_privateca_certificate.default.pem_certificate // tls_self_signed_cert.default.cert_pem
        private_key = tls_private_key.cert_key.private_key_pem // tls_private_key.default.private_key_pem
      }
    }
    /* certificate_ids = [
      "projects/myprj/regions/europe-west1/sslCertificates/my-cert"
    ] */
  }
  /* urlmap_config = {
    default_service = "default"
    host_rules = [{
      hosts        = ["*"]
      path_matcher = "pathmap"
    }]
    path_matchers = {
      pathmap = {
        default_service = "default"
        path_rules = [
          {
            paths   = ["/api1", "/api1/*"]
            service = "svc-1" //local.cloudrun_svcnames[0]
          },
          {
            paths   = ["/api2", "/api2/*"]
            service = "svc-2" //ocal.cloudrun_svcnames[1]
          }
        ]
      }
    }
  } */
  vpc_config = {
    network    = data.google_compute_network.host-network.id
    subnetwork = data.google_compute_subnetwork.host-subnetwork.self_link
  }
}
