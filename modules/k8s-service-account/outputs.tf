output "name" {
  description = "The name of the created service account"
  value       = var.create_resources ? kubernetes_service_account.service_account[0].metadata[0].name : ""

  depends_on = [kubernetes_role_binding.service_account_role_binding]
}

output "token_secret_name" {
  description = "The name of the secret that holds the default ServiceAccount token that can be used to authenticate to the Kubernetes API."
  value       = var.create_resources ? kubernetes_service_account.service_account[0].default_secret_name : ""

  depends_on = [kubernetes_role_binding.service_account_role_binding]
}

