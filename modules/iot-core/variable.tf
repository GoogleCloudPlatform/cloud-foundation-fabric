variable "project_id" {
   description = "The project ID where all resources will be launched."
  type = string
}

variable "region" {
   description = "Region for IoT registry"
  type = string
}

variable "devices" {
  description = "Devices map to be registered in the IoT Registry in the form DEVICE_ID: DEVICE_CERTIFICATE"
  type        = map(string)
  default     = {}
}