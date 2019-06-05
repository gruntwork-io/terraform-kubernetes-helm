output "name" {
  description = "The name of the created namespace."
  value       = element(concat(kubernetes_namespace.namespace.*.id, [""]), 0)
}

output "rbac_access_all_role" {
  description = "The name of the RBAC role that grants admin level permissions on the namespace."
  value       = module.namespace_roles.rbac_access_all_role
}

output "rbac_access_read_only_role" {
  description = "The name of the RBAC role that grants read only permissions on the namespace."
  value       = module.namespace_roles.rbac_access_read_only_role
}

output "rbac_tiller_metadata_access_role" {
  description = "The name of the RBAC role that grants minimal permissions for Tiller to manage its metadata. Use this role if Tiller will be deployed into this namespace."
  value       = module.namespace_roles.rbac_tiller_metadata_access_role
}

output "rbac_tiller_resource_access_role" {
  description = "The name of the RBAC role that grants minimal permissions for Tiller to manage resources in this namespace."
  value       = module.namespace_roles.rbac_tiller_resource_access_role
}
