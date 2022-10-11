output "redirect_hostnames" {
  description = "Hostname with corrosponding redirects"
  value       = var.hostname_redirect
}

output "dv_keys" {
  description = "show our DV CNAME keys we need to add to DNS"
  value       = resource.akamai_property.aka_property.hostnames[*].cert_status[0]
}
