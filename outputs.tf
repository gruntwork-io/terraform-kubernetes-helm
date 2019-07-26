output "tiller_namespace" {
  description = "The name of the namespace that houses Tiller."
  value       = module.tiller_namespace.name
}

output "resource_namespace" {
  description = "The name of the namespace where Tiller will deploy resources into."
  value       = module.resource_namespace.name
}

output "helm_client_tls_private_key_pem" {
  description = "The private key of the TLS certificate key pair to use for the helm client."
  sensitive   = true
  value       = module.helm_client_tls_certs.tls_certificate_key_pair_private_key_pem
}

output "helm_client_tls_public_cert_pem" {
  description = "The public certificate of the TLS certificate key pair to use for the helm client."
  sensitive   = true
  value       = module.helm_client_tls_certs.tls_certificate_key_pair_certificate_pem
}

output "helm_client_tls_ca_cert_pem" {
  description = "The CA certificate of the TLS certificate key pair to use for the helm client."
  sensitive   = true
  value       = module.helm_client_tls_certs.ca_tls_certificate_key_pair_certificate_pem
}
