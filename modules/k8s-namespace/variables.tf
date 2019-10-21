# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These variables are expected to be passed in by the operator when calling this terraform module.
# ---------------------------------------------------------------------------------------------------------------------

variable "name" {
  description = "The name of the namespace to be created."
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL MODULE PARAMETERS
# These variables have defaults, but may be overridden by the operator.
# ---------------------------------------------------------------------------------------------------------------------

variable "labels" {
  description = "Map of string key value pairs that can be used to organize and categorize the namespace and roles. See the Kubernetes Reference for more info (https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)."
  type        = map(string)
  default     = {}
}

variable "annotations" {
  description = "Map of string key default pairs that can be used to store arbitrary metadata on the namespace and roles. See the Kubernetes Reference for more info (https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/)."
  type        = map(string)
  default     = {}
}

variable "create_resources" {
  description = "Set to false to have this module skip creating resources. This weird parameter exists solely because Terraform does not support conditional modules. Therefore, this is a hack to allow you to conditionally decide if the Namespace should be created or not."
  type        = bool
  default     = true
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
  type        = list(string)
  default     = []
}
