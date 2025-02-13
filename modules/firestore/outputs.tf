/**
 * Copyright 2024 Google LLC
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

output "firestore_database" {
  description = "Firestore database."
  value       = var.database_create ? google_firestore_database.firestore_database[0] : null
}

output "firestore_document_ids" {
  description = "Firestore document ids."
  value       = [for v in google_firestore_document.firestore_documents : v.id]
}
output "firestore_documents" {
  description = "Firestore documents."
  value       = google_firestore_document.firestore_documents
}

output "firestore_field_ids" {
  description = "Firestore field ids."
  value       = [for v in google_firestore_field.firestore_fields : v.id]
}

output "firestore_fields" {
  description = "Firestore fields."
  value       = google_firestore_field.firestore_fields
}

output "firestore_index_ids" {
  description = "Firestore index ids."
  value       = { for k, v in google_firestore_index.firestore_indexes : k => v.id }
}

output "firestore_indexes" {
  description = "Firestore indexes."
  value       = google_firestore_index.firestore_indexes
}

