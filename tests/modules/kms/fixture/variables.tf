/**
 * Copyright 2021 Google LLC
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

variable "iam" {
  type = map(list(string))
  default = {
    "roles/owner" = ["user:ludo@ludomagno.net"]
  }
}

variable "key_iam" {
  type = map(map(list(string)))
  default = {
    key-a = {
      "roles/owner" = ["user:ludo@ludomagno.net"]
    }
  }
}

variable "key_purpose" {
  type = map(object({
    purpose = string
    version_template = object({
      algorithm        = string
      protection_level = string
    })
  }))
  default = {
    key-b = {
      purpose          = "ENCRYPT_DECRYPT"
      version_template = null
    }
    key-c = {
      purpose = "ASYMMETRIC_SIGN"
      version_template = {
        algorithm        = "EC_SIGN_P384_SHA384"
        protection_level = null
      }
    }
  }
}

variable "key_purpose_defaults" {
  type = object({
    purpose = string
    version_template = object({
      algorithm        = string
      protection_level = string
    })
  })
  default = {
    purpose          = null
    version_template = null
  }
}

variable "keyring" {
  type = object({
    location = string
    name     = string
  })
  default = {
    location = "europe-west1"
    name     = "test-module"
  }
}

variable "keyring_create" {
  type    = bool
  default = true
}

variable "keys" {
  type = map(object({
    rotation_period = string
    labels          = map(string)
  }))
  default = {
    key-a = null
    key-b = { rotation_period = "604800s", labels = null }
    key-c = { rotation_period = null, labels = { env = "test" } }
  }
}

variable "project_id" {
  type    = string
  default = "my-project"
}
