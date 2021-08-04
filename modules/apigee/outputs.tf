output "subscription_type" {
    description = "Apigee subscription type."
    value       = google_apigee_organization.apigee_org.subscription_type
}

output "org_ca_certificate" {
    description = "Apigee organization CA certificate."
    value       = google_apigee_organization.apigee_org.ca_certificate
}

output "org_id" {
    description = "Apigee Organization ID."
    value       = google_apigee_organization.apigee_org.id
}