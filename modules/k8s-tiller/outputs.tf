output "deployment_name" {
  description = "The name of the Deployment resource that manages the Tiller Pods."
  value       = kubernetes_deployment.tiller.metadata[0].name
}

output "service_name" {
  description = "The name of the Service resource that fronts the Tiller Pods."
  value       = kubernetes_service.tiller.metadata[0].name
}

output "tiller_ca_tls_certificate_key_pair_secret_namespace" {
  description = "The Namespace where the Tiller TLS CA certs are stored. Set only if var.tiller_tls_gen_method is not \"none\""

  value = var.tiller_tls_gen_method == "provider" ? module.tiller_tls_certs.ca_tls_certificate_key_pair_secret_namespace : var.tiller_tls_gen_method == "kubergrunt" ? var.tiller_tls_ca_cert_secret_namespace : ""

  depends_on = [null_resource.tiller_tls_ca_certs]
}

output "tiller_ca_tls_certificate_key_pair_secret_name" {
  description = "The name of the Secret resource where the Tiller TLS CA certs are stored. Set only if var.tiller_tls_gen_method is not \"none\""

  value = var.tiller_tls_gen_method == "provider" ? module.tiller_tls_certs.ca_tls_certificate_key_pair_secret_name : var.tiller_tls_gen_method == "kubergrunt" ? local.tiller_tls_ca_certs_secret_name : ""

  depends_on = [null_resource.tiller_tls_ca_certs]
}

output "tiller_tls_certificate_key_pair_secret_namespace" {
  description = "The Namespace where the Tiller TLS certs are stored. Set only if var.tiller_tls_gen_method is not \"none\""

  value = var.tiller_tls_gen_method == "provider" ? module.tiller_tls_certs.signed_tls_certificate_key_pair_secret_namespace : var.tiller_tls_gen_method == "kubergrunt" ? var.namespace : ""

  depends_on = [null_resource.tiller_tls_certs]
}

output "tiller_tls_certificate_key_pair_secret_name" {
  description = "The name of the Secret resource where the Tiller TLS certs are stored. Set only if var.tiller_tls_gen_method is not \"none\""

  value = var.tiller_tls_gen_method == "provider" ? module.tiller_tls_certs.signed_tls_certificate_key_pair_secret_name : var.tiller_tls_gen_method == "kubergrunt" ? local.tiller_tls_certs_secret_name : ""

  depends_on = [null_resource.tiller_tls_certs]
}
