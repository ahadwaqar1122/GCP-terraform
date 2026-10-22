output "iap_ssh_rule_name" {
  description = "Name of the IAP SSH firewall rule, if created."
  value       = try(google_compute_firewall.allow_iap_ssh[0].name, null)
}

output "public_ssh_rule_name" {
  description = "Name of the public SSH firewall rule, if created."
  value       = try(google_compute_firewall.allow_ssh[0].name, null)
}
