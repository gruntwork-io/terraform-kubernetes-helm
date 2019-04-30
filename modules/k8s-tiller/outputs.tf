output "deployment_name" {
  description = "The name of the Deployment resource that manages the Tiller Pods."
  value       = "${kubernetes_deployment.tiller.metadata.0.name}"
}

output "service_name" {
  description = "The name of the Service resource that fronts the Tiller Pods."
  value       = "${kubernetes_service.tiller.metadata.0.name}"
}
