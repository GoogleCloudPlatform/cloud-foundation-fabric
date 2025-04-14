/**
 * Copyright 2025 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

resource "google_data_loss_prevention_deidentify_template" "dlp_deidentify_template" {
  count        = var.dlp_config == null ? 1 : 0
  parent       = "projects/${module.project.project_id}/locations/${var.regions.primary}"
  description  = "SecOps Anonymization pipeline deidentify template."
  display_name = "sample_deidentify_config_template"

  deidentify_config {
    info_type_transformations {
      transformations {
        info_types {
          name = "PHONE_NUMBER"
        }
        primitive_transformation {
          replace_config {
            new_value {
              integer_value = 3333333333
            }
          }
        }
      }
      transformations {
        info_types {
          name = "AGE"
        }
        primitive_transformation {
          replace_config {
            new_value {
              integer_value = 10
            }
          }
        }
      }
      transformations {
        info_types {
          name = "EMAIL_ADDRESS"
        }

        primitive_transformation {
          replace_config {
            new_value {
              string_value = "john.doe@fakedomain.com"
            }
          }
        }
      }
      transformations {
        info_types {
          name = "LAST_NAME"
        }
        primitive_transformation {
          replace_config {
            new_value {
              string_value = "doe"
            }
          }
        }
      }
      transformations {
        info_types {
          name = "PERSON_NAME"
        }
        primitive_transformation {
          replace_config {
            new_value {
              string_value = "john"
            }
          }
        }
      }
      transformations {
        info_types {
          name = "DATE_OF_BIRTH"
        }
        primitive_transformation {
          replace_config {
            new_value {
              date_value {
                year  = 1990
                month = 1
                day   = 1
              }
            }
          }
        }
      }
      transformations {
        info_types {
          name = "CREDIT_CARD_NUMBER"
        }

        primitive_transformation {
          replace_config {
            new_value {
              string_value = "1234567812345678"
            }
          }
        }
      }
      transformations {
        info_types {
          name = "CREDIT_CARD_TRACK_NUMBER"
        }

        primitive_transformation {
          replace_config {
            new_value {
              string_value = "1234567812345678"
            }
          }
        }
      }
      transformations {
        info_types {
          name = "ETHNIC_GROUP"
        }

        primitive_transformation {
          replace_config {
            new_value {
              string_value = "None"
            }
          }
        }
      }
      transformations {
        info_types {
          name = "GENDER"
        }

        primitive_transformation {
          replace_config {
            new_value {
              string_value = "Gender"
            }
          }
        }
      }
      transformations {
        info_types {
          name = "IBAN_CODE"
        }

        primitive_transformation {
          replace_config {
            new_value {
              string_value = "2131312312312312"
            }
          }
        }
      }
      transformations {
        info_types {
          name = "PASSPORT"
        }

        primitive_transformation {
          replace_config {
            new_value {
              string_value = "2131312312312312"
            }
          }
        }
      }
      transformations {
        info_types {
          name = "STREET_ADDRESS"
        }

        primitive_transformation {
          replace_config {
            new_value {
              string_value = "street address"
            }
          }
        }
      }
      transformations {
        info_types {
          name = "SWIFT_CODE"
        }

        primitive_transformation {
          replace_config {
            new_value {
              string_value = "2131312312312312"
            }
          }
        }
      }
      transformations {
        info_types {
          name = "VEHICLE_IDENTIFICATION_NUMBER"
        }

        primitive_transformation {
          replace_config {
            new_value {
              string_value = "2131312312312312"
            }
          }
        }
      }
    }
  }
}

resource "google_data_loss_prevention_inspect_template" "dlp_inspect_template" {
  count        = var.dlp_config == null ? 1 : 0
  parent       = "projects/${module.project.project_id}/locations/${var.regions.primary}"
  description  = "Data Loss prevention sample inspect config."
  display_name = "sample_inspect_config_template"

  inspect_config {
    info_types {
      name = "ADVERTISING_ID"
    }
    info_types {
      name = "AGE"
    }
    info_types {
      name = "CREDIT_CARD_NUMBER"
    }
    info_types {
      name = "CREDIT_CARD_TRACK_NUMBER"
    }
    info_types {
      name = "EMAIL_ADDRESS"
    }
    info_types {
      name = "DATE_OF_BIRTH"
    }
    info_types {
      name = "ETHNIC_GROUP"
    }
    info_types {
      name = "GENDER"
    }
    info_types {
      name = "IBAN_CODE"
    }
    info_types {
      name = "PASSPORT"
    }
    info_types {
      name = "PERSON_NAME"
    }
    info_types {
      name = "FIRST_NAME"
    }
    info_types {
      name = "LAST_NAME"
    }
    info_types {
      name = "PHONE_NUMBER"
    }
    info_types {
      name = "STREET_ADDRESS"
    }
    info_types {
      name = "SWIFT_CODE"
    }
    info_types {
      name = "VEHICLE_IDENTIFICATION_NUMBER"
    }
    min_likelihood = "POSSIBLE"
  }
}
