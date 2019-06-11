output "name" {
  description = "The name of the created service account"
  value       = kubernetes_service_account.service_account.metadata[0].name

  depends_on = [kubernetes_role_binding.service_account_role_binding]
}

output "token_secret_name" {
  description = "The name of the secret that holds the default ServiceAccount token that can be used to authenticate to the Kubernetes API."
  value       = kubernetes_service_account.service_account.default_secret_name

  depends_on = [kubernetes_role_binding.service_account_role_binding]
}

