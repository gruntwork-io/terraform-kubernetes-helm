output "name" {
  description = "The name of the created service account"
  value       = "${kubernetes_service_account.service_account.metadata.0.name}"
}

output "depended_on" {
  description = "This output can be used to depend on the resources in this module."
  value       = "${null_resource.dependency_setter.id}"
}
