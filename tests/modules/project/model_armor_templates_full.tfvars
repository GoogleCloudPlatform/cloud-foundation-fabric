model_armor_templates = {
  full = {
    location = "eu"
    labels = {
      env = "test"
    }
    filters = {
      malicious_uris = false
      pi_and_jailbreak = {
        confidence_level = "LOW_AND_ABOVE"
      }
      rai = {
        DANGEROUS         = "MEDIUM_AND_ABOVE"
        HARASSMENT        = "HIGH"
        HATE_SPEECH       = "MEDIUM_AND_ABOVE"
        SEXUALLY_EXPLICIT = "LOW_AND_ABOVE"
      }
      sdp = {
        inspect_template    = "projects/my-project/locations/eu/inspectTemplates/inspect"
        deidentify_template = "projects/my-project/locations/eu/deidentifyTemplates/deidentify"
      }
    }
    metadata = {
      enforcement_type                   = "INSPECT_AND_BLOCK"
      ignore_partial_invocation_failures = true
      log_sanitize_operations            = true
      log_template_operations            = true
      multi_language_detection           = true
      custom_llm_response_safety_error = {
        code    = 451
        message = "Response blocked."
      }
      custom_prompt_safety_error = {
        code    = 400
        message = "Prompt blocked."
      }
    }
  }
  sdp-empty = {
    location = "us-central1"
    filters = {
      sdp = {}
    }
  }
}
