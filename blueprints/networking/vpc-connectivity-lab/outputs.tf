output "ping_commands" {
  value = var.test_vms ? join("\n", [for instance, _ in local.test-vms : "ping -c 1 ${instance}.example"]) : ""
}
