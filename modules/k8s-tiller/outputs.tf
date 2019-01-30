output "done" {
  description = "This output can be used to depend on the resources in this module. Specifically, waiting for Tiller to be deployed and the local helm client to be configured."
  value       = true

  depends_on = ["null_resource.tiller", "null_resource.grant_access_to_tiller", "null_resource.configure_local_helm_client"]
}
