output "depended_on" {
  description = "This output can be used to depend on the resources in this module. Specifically, waiting for Tiller to be deployed and the local helm client to be configured."
  value       = "${null_resource.dependency_setter.id}"
}
