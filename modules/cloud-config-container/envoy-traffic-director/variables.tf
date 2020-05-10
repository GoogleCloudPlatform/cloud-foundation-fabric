variable "envoy_image" {
  description = "Envoy Proxy container image to use."
  type        = string
  default     = "envoyproxy/envoy:v1.14.1"
}

variable "gcp_logging" {
  description = "Should container logs be sent to Google Cloud Logging"
  type        = bool
  default     = true
}