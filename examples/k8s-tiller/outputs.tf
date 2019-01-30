output "resource_namespace_name" {
  description = "Name of the created resource namespace"
  value       = "${module.resource_namespace.name}"
}

output "resource_namespace_rbac_access_all_role" {
  description = "The name of the RBAC role that grants admin level permissions on the resource namespace."
  value       = "${module.resource_namespace.rbac_access_all_role}"
}

output "resource_namespace_rbac_access_read_only_role" {
  description = "The name of the RBAC role that grants read only permissions on the resource namespace."
  value       = "${module.resource_namespace.rbac_access_read_only_role}"
}
