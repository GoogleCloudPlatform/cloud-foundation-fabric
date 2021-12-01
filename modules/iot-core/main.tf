provider "google" {
  project = var.project_id
  region = var.region
}

#-------------------------------------------------------
# Enable APIs
#    - Pub/Sub
#    - Cloud IoT
#-------------------------------------------------------

module "project_services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "3.3.0"

  project_id    = var.project_id
  activate_apis =  [
    "pubsub.googleapis.com",
    "cloudiot.googleapis.com"
  ]

  disable_services_on_destroy = false
  disable_dependent_services  = false
}

#---------------------------------------------------------
# Create Pub/Sub Topics
#---------------------------------------------------------

resource "google_pubsub_topic" "default-devicestatus" {
  name = "default-devicestatus"
}

resource "google_pubsub_topic" "default-telemetry" {
  name = "default-telemetry"
}

resource "google_pubsub_topic" "additional-telemetry" {
  name = "additional-telemetry"
}

#---------------------------------------------------------
# Create IoT Core Registry
#---------------------------------------------------------

resource "google_cloudiot_registry" "test-registry" {
  name     = "cloudiot-registry"

  event_notification_configs {
    pubsub_topic_name = google_pubsub_topic.additional-telemetry.id
    subfolder_matches = "test/path"
  }

  event_notification_configs {
    pubsub_topic_name = google_pubsub_topic.default-telemetry.id
    subfolder_matches = ""
  }

  state_notification_config = {
    pubsub_topic_name = google_pubsub_topic.default-devicestatus.id
  }

  mqtt_config = {
    mqtt_enabled_state = "MQTT_ENABLED"
  }

  http_config = {
    http_enabled_state = "HTTP_ENABLED"
  }

  log_level = "INFO"

}

#---------------------------------------------------------
# Create IoT Core Device
# certificate created using: openssl req -x509 -newkey rsa:2048 -keyout rsa_private.pem -nodes -out rsa_cert.pem -subj "/CN=unused"
#---------------------------------------------------------

resource "google_cloudiot_device" "device" {
  for_each = coalesce(var.devices, {})
  name     = each.key
  registry = google_cloudiot_registry.test-registry.id

  credentials {
    public_key {
        format = "RSA_X509_PEM"
        key = file(each.value)
    }
  }

  blocked = false

  log_level = "INFO"

  metadata = {
    test_key_1 = "test_value_1"
  }

  gateway_config {
    gateway_type = "NON_GATEWAY"
  }
}