resource "google_privateca_ca_pool" "default" {
  project  = var.project_id
  name     = "Acme-CA-pool"
  location = var.region
  tier     = "ENTERPRISE"
  /* publishing_options {
    publish_ca_cert = true
    publish_crl     = true
  } */
}

resource "google_privateca_certificate_authority" "default" {
  project  = var.project_id
  certificate_authority_id = "Acme-CA"
  location                 = var.region
  pool                     = google_privateca_ca_pool.default.name
  config {
    subject_config {
      subject {
        //country_code        = "us"
        common_name         = "Acme-CA"
        organization        = "Acme"
        //organizational_unit = "enterprise"
        //locality            = "mountain view"
        //province            = "california"
        //street_address      = "1600 amphitheatre parkway"
        //postal_code         = "94109"
      }
    }
    x509_config {
      ca_options {
        is_ca = true
      }
      key_usage {
        base_key_usage {
          cert_sign = true
          crl_sign  = true
        }
        extended_key_usage {
          client_auth = true
          server_auth = true
        }
      }
    }
  }
  //type = "SELF_SIGNED"
  lifetime = "7776000s" // 90 days
  key_spec {
    algorithm = "EC_P384_SHA384"
  }

  // Disable CA deletion related safe checks for easier cleanup while testing.
  deletion_protection                    = false
  skip_grace_period                      = true
  ignore_active_certificates_on_deletion = true
}

resource "tls_private_key" "cert_key" {
  /* algorithm   = "ECDSA"
  ecdsa_curve = "P256" */
  algorithm   = "RSA"
}

resource "google_privateca_certificate" "default" {
  project  = var.project_id
  certificate_authority = google_privateca_certificate_authority.default.certificate_authority_id
  location                 = var.region
  pool                     = google_privateca_ca_pool.default.name
  lifetime              = "2592000s" // 30 days
  name                  = "kong-be-certificate-01"
  config {
    subject_config  {
      subject {
        common_name = "acme.org"
        organization        = "Acme"
/*         country_code = "us"
        organizational_unit = "enterprise"
        locality = "mountain view"
        province = "california"
        street_address = "1600 amphitheatre parkway" */
      } 
      subject_alt_name {
        dns_names = ["acme.org"]
        /* email_addresses = ["email@example.com"]
        ip_addresses = ["127.0.0.1"]
        uris = ["http://www.ietf.org/rfc/rfc3986.txt"] */
      }
    }
    x509_config {
      ca_options {
        is_ca = false
      }
      key_usage {
        base_key_usage {
          /* cert_sign = true
          crl_sign = true */
          key_agreement = true
        }
        extended_key_usage {
          server_auth = true
        }
      }
      /* name_constraints {
        critical                  = true
        permitted_dns_names       = ["*.example.com"]
        excluded_dns_names        = ["*.deny.example.com"]
        permitted_ip_ranges       = ["10.0.0.0/8"]
        excluded_ip_ranges        = ["10.1.1.0/24"]
        permitted_email_addresses = [".example.com"]
        excluded_email_addresses  = [".deny.example.com"]
        permitted_uris            = [".example.com"]
        excluded_uris             = [".deny.example.com"]
      } */
    }
    public_key {
      format = "PEM"
      key = base64encode(tls_private_key.cert_key.public_key_pem)
    }
  }
  //pem_csr               = tls_cert_request.example.cert_request_pem
}