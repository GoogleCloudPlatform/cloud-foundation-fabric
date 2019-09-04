provider "google" {
  credentials = "${file("credentials.json")}"
}
