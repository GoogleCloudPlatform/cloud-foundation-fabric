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

variable "iam" {
  description = "IAM bindings in {ROLE => [MEMBERS]} format."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "iam_bindings" {
  description = "Authoritative IAM bindings in {KEY => {role = ROLE, members = [], condition = {}}}. Keys are arbitrary."
  type = map(object({
    members = list(string)
    role    = string
    condition = optional(object({
      expression  = string
      title       = string
      description = optional(string)
    }))
  }))
  nullable = false
  default  = {}
}

variable "iam_bindings_additive" {
  description = "Individual additive IAM bindings. Keys are arbitrary."
  type = map(object({
    member = string
    role   = string
    condition = optional(object({
      expression  = string
      title       = string
      description = optional(string)
    }))
  }))
  nullable = false
  default  = {}
}

variable "iam_by_principals_additive" {
  description = "Additive IAM binding in {PRINCIPAL => [ROLES]} format. Principals need to be statically defined to avoid cycle errors."
  type        = map(list(string))
  default     = {}
  nullable    = false

  validation {
    error_message = format(
      "Cannot refer to the same principal/role pair from iam_by_principals_additive and iam_bindings_additive. The following pairs are present on both sides:\n%s",
      join("\n", [
        // the iterable here is the same as the condition expression below.
        // We duplicate it here to show the offending pairs in the error.
        for x in setintersection(
          [
            for k, v in var.iam_bindings_additive :
            [v.member, v.role]
            if v.condition == null
          ],
          concat([
            for k, v in var.iam_by_principals_additive :
            setproduct([k], v)
          ]...),
        ) :
        "${x.0} ${x.1}"
      ])
    )
    condition = (
      0 == length(setintersection(
        // the set of all additive bindings without conditions
        [
          for k, v in var.iam_bindings_additive :
          [v.member, v.role]
          if v.condition == null
        ],
        // the set of all pairs of all pairs principal x role
        concat([
          for k, v in var.iam_by_principals_additive :
          setproduct([k], v)
        ]...)
      ))
    )
  }

}

variable "iam_by_principals" {
  description = "Authoritative IAM binding in {PRINCIPAL => [ROLES]} format. Principals need to be statically defined to avoid cycle errors. Merged internally with the `iam` variable."
  type        = map(list(string))
  default     = {}
  nullable    = false
}
