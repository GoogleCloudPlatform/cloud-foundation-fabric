output "endpoint" {
    description = "Internal endpoint of the Apigee instance."
    value = google_apigee_instance.apigee_instance.host
}