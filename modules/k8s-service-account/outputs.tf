output "name" {
  description = "The name of the created service account"
  value       = "${kubernetes_service_account.service_account.metadata.0.name}"
}
