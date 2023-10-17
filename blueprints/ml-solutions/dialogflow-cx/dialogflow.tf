resource "google_dialogflow_cx_agent" "agent" {
  project                    = module.project.project_id
  display_name               = "Agent"
  location                   = var.region
  default_language_code      = var.language
  time_zone                  = "Europe/Madrid"
  description                = "Demo example agent."
  enable_stackdriver_logging = true
  enable_spell_correction    = true
  speech_to_text_settings {
    enable_speech_adaptation = true
  }
}

resource "google_dialogflow_cx_webhook" "webhook" {
  provider     = google-beta
  parent       = google_dialogflow_cx_agent.agent.id
  display_name = "webhook"
  service_directory {
    service = google_service_directory_service.service.name
    generic_web_service {
      uri = "${module.cloud_run.service.status.0.url}/${var.webhook_config.url_path}"
      allowed_ca_certs = [
        filebase64("server_tf.der")
      ]
    }
  }
  depends_on = [null_resource.der]
}

