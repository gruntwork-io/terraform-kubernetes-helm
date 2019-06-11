output "tiller_namespace" {
  description = "The name of the namespace that houses Tiller."
  value       = module.tiller_namespace.name
}

output "resource_namespace" {
  description = "The name of the namespace where Tiller will deploy resources into."
  value       = module.resource_namespace.name
}
