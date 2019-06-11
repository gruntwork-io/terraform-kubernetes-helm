output "tls_certificate_key_pair_private_key_pem" {
  description = "The private key of the generated TLS certs in PEM format."
  value       = tls_private_key.cert.private_key_pem
  sensitive   = true
}

output "tls_certificate_key_pair_public_key_pem" {
  description = "The public key of the generated TLS certs in PEM format."
  value       = tls_private_key.cert.public_key_pem
  sensitive   = true
}

output "tls_certificate_key_pair_certificate_pem" {
  description = "The public certificate of the generated TLS certs in PEM format."
  value       = tls_locally_signed_cert.cert.cert_pem
  sensitive   = true
}

output "ca_tls_certificate_key_pair_certificate_pem" {
  description = "The public certificate of the CA TLS certs in PEM format."

  value = data.kubernetes_secret.ca_certs.data["${var.ca_tls_certificate_key_pair_secret_filename_base}.crt"]

  sensitive = true
}

output "tls_certificate_key_pair_secret_namespace" {
  description = "Namespace where the signed TLS certificate key pair is stored."
  value = element(
    concat(kubernetes_secret.signed_tls.*.metadata.0.namespace, [""]),
    0,
  )
}

output "tls_certificate_key_pair_secret_name" {
  description = "Name of the Secret resource where the signed TLS certificate key pair is stored."
  value = element(
    concat(kubernetes_secret.signed_tls.*.metadata.0.name, [""]),
    0,
  )
}
