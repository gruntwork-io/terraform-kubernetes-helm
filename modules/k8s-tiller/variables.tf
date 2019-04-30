variable "tiller_service_account_name" {}

variable "tiller_service_account_token_secret_name" {}

variable "tiller_tls_secret_name" {}

variable "namespace" {}

variable "deployment_name" {
  default = "tiller-deploy"
}

variable "deployment_labels" {
  type    = "map"
  default = {}
}

variable "deployment_annotations" {
  type    = "map"
  default = {}
}

variable "deployment_replicas" {
  default = 1
}

variable "service_name" {
  default = "tiller-deploy"
}

variable "service_labels" {
  type    = "map"
  default = {}
}

variable "service_annotations" {
  type    = "map"
  default = {}
}

variable "tiller_tls_key_file_name" {
  default = "tls.key"
}

variable "tiller_tls_cert_file_name" {
  default = "tls.crt"
}

variable "tiller_tls_cacert_file_name" {
  default = "ca.crt"
}

variable "tiller_image" {
  default = "gcr.io/kubernetes-helm/tiller"
}

variable "tiller_image_version" {
  default = "v2.11.0"
}

variable "tiller_image_pull_policy" {
  default = "IfNotPresent"
}

variable "tiller_command_args" {
  default = [
    # Use Secrets for storing release info, which contain the values.yaml file info.
    "--storage=secret",

    # Set to only listen on localhost so that it is only available via port-forwarding. The helm client (and terraform
    # helm provider) use port-forwarding to communicate with Tiller so this is a safer default.
    "--listen=localhost:44134",
  ]
}

variable "tiller_history_max" {
  default = 0
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE DEPENDENCIES
# Workaround Terraform limitation where there is no module depends_on.
# See https://github.com/hashicorp/terraform/issues/1178 for more details.
# This can be used to make sure the module resources are created after other bootstrapping resources have been created.
# For example, in GKE, the default permissions are such that you do not have enough authorization to be able to create
# additional Roles in the system. Therefore, you need to first create a ClusterRoleBinding to promote your account
# before you can apply this module. In this use case, you can pass in the ClusterRoleBinding as a dependency into this
# module:
# dependencies = ["${kubernetes_cluster_role_binding.user.metadata.0.name}"]
# ---------------------------------------------------------------------------------------------------------------------

variable "dependencies" {
  description = "Create a dependency between the resources in this module to the interpolated values in this list (and thus the source resources). In other words, the resources in this module will now depend on the resources backing the values in this list such that those resources need to be created before the resources in this module, and the resources in this module need to be destroyed before the resources in the list."
  type        = "list"
  default     = []
}
