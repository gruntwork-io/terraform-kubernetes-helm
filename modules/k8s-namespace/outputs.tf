output "name" {
  description = "The name of the created namespace."
  value       = "${kubernetes_namespace.namespace.id}"
}

output "rbac_access_all_role" {
  description = "The name of the RBAC role that grants admin level permissions on the namespace."
  value       = "${kubernetes_role.rbac_role_access_all.metadata.0.name}"
}

output "rbac_access_read_only_role" {
  description = "The name of the RBAC role that grants read only permissions on the namespace."
  value       = "${kubernetes_role.rbac_role_access_read_only.metadata.0.name}"
}

output "rbac_tiller_metadata_access_role" {
  description = "The name of the RBAC role that grants minimal permissions for Tiller to manage its metadata. Use this role if Tiller will be deployed into this namespace."
  value       = "${kubernetes_role.rbac_tiller_metadata_access.metadata.0.name}"
}

output "rbac_tiller_resource_access_role" {
  description = "The name of the RBAC role that grants minimal permissions for Tiller to manage resources in this namespace."
  value       = "${kubernetes_role.rbac_tiller_resource_access.metadata.0.name}"
}
