output "name" {
  description = "The name of the created namespace."
  value       = "${kubernetes_namespace.namespace.id}"
}

output "rbac_access_all_role" {
  description = "The name of the RBAC role that grants admin level permissions on the namespace."
  value       = "${var.name}-access-all"
  depends_on  = ["null_resource.rbac_role_access_all"]
}

output "rbac_access_read_only_role" {
  description = "The name of the RBAC role that grants read only permissions on the namespace."
  value       = "${var.name}-access-read-only"
  depends_on  = ["null_resource.rbac_role_access_read_only"]
}
