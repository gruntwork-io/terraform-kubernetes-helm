output "ca_tls_certificate_key_pair_secret_namespace" {
  description = "Namespace where the CA TLS certificate key pair is stored."
  value = element(
    concat(kubernetes_secret.ca_secret.*.metadata.0.namespace, [""]),
    0,
  )
}

output "ca_tls_certificate_key_pair_secret_name" {
  description = "Name of the Secret resource where the CA TLS certificate key pair is stored."
  value = element(
    concat(kubernetes_secret.ca_secret.*.metadata.0.name, [""]),
    0,
  )
}

output "signed_tls_certificate_key_pair_secret_namespace" {
  description = "Namespace where the signed TLS certificate key pair is stored."
  value = element(
    concat(kubernetes_secret.signed_tls.*.metadata.0.namespace, [""]),
    0,
  )
}

output "signed_tls_certificate_key_pair_secret_name" {
  description = "Name of the Secret resource where the signed TLS certificate key pair is stored."
  value = element(
    concat(kubernetes_secret.signed_tls.*.metadata.0.name, [""]),
    0,
  )
}

