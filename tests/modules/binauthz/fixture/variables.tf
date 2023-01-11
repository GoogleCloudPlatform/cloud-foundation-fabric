/**
 * Copyright 2022 Google LLC
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

variable "project_id" {
  type    = string
  default = "my_project"
}

variable "global_policy_evaluation_mode" {
  type    = string
  default = null
}

variable "admission_whitelist_patterns" {
  type = list(string)
  default = [
    "gcr.io/google_containers/*"
  ]
}

variable "default_admission_rule" {
  type = object({
    evaluation_mode  = string
    enforcement_mode = string
    attestors        = list(string)
  })
  default = {
    evaluation_mode  = "ALWAYS_ALLOW"
    enforcement_mode = "ENFORCED_BLOCK_AND_AUDIT_LOG"
    attestors        = null
  }
}

variable "cluster_admission_rules" {
  type = map(object({
    evaluation_mode  = string
    enforcement_mode = string
    attestors        = list(string)
  }))
  default = {
    "europe-west1-c.cluster" = {
      evaluation_mode  = "REQUIRE_ATTESTATION"
      enforcement_mode = "ENFORCED_BLOCK_AND_AUDIT_LOG"
      attestors        = ["test"]
    }
  }
}

variable "attestors_config" {
  description = "Attestors configuration"
  type = map(object({
    note_reference  = string
    iam             = map(list(string))
    pgp_public_keys = list(string)
    pkix_public_keys = list(object({
      id                  = string
      public_key_pem      = string
      signature_algorithm = string
    }))
  }))
  default = {
    "test" : {
      note_reference = null
      pgp_public_keys = [
        <<EOT
        mQENBFtP0doBCADF+joTiXWKVuP8kJt3fgpBSjT9h8ezMfKA4aXZctYLx5wslWQl
        bB7Iu2ezkECNzoEeU7WxUe8a61pMCh9cisS9H5mB2K2uM4Jnf8tgFeXn3akJDVo0
        oR1IC+Dp9mXbRSK3MAvKkOwWlG99sx3uEdvmeBRHBOO+grchLx24EThXFOyP9Fk6
        V39j6xMjw4aggLD15B4V0v9JqBDdJiIYFzszZDL6pJwZrzcP0z8JO4rTZd+f64bD
        Mpj52j/pQfA8lZHOaAgb1OrthLdMrBAjoDjArV4Ek7vSbrcgYWcI6BhsQrFoxKdX
        83TZKai55ZCfCLIskwUIzA1NLVwyzCS+fSN/ABEBAAG0KCJUZXN0IEF0dGVzdG9y
        IiA8ZGFuYWhvZmZtYW5AZ29vZ2xlLmNvbT6JAU4EEwEIADgWIQRfWkqHt6hpTA1L
        uY060eeM4dc66AUCW0/R2gIbLwULCQgHAgYVCgkICwIEFgIDAQIeAQIXgAAKCRA6
        0eeM4dc66HdpCAC4ot3b0OyxPb0Ip+WT2U0PbpTBPJklesuwpIrM4Lh0N+1nVRLC
        51WSmVbM8BiAFhLbN9LpdHhds1kUrHF7+wWAjdR8sqAj9otc6HGRM/3qfa2qgh+U
        WTEk/3us/rYSi7T7TkMuutRMIa1IkR13uKiW56csEMnbOQpn9rDqwIr5R8nlZP5h
        MAU9vdm1DIv567meMqTaVZgR3w7bck2P49AO8lO5ERFpVkErtu/98y+rUy9d789l
        +OPuS1NGnxI1YKsNaWJF4uJVuvQuZ1twrhCbGNtVorO2U12+cEq+YtUxj7kmdOC1
        qoIRW6y0+UlAc+MbqfL0ziHDOAmcqz1GnROg
        =6Bvm
        EOT
      ]
      pkix_public_keys = null
      iam = {
        "roles/viewer" = ["user:user1@my_org.com"]
      }
    }
  }
}

