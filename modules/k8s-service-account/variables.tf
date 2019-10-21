# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These variables are expected to be passed in by the operator when calling this terraform module.
# ---------------------------------------------------------------------------------------------------------------------

variable "name" {
  description = "The name of the service account to be created."
  type        = string
}

variable "namespace" {
  description = "The namespace where the service account is created."
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL MODULE PARAMETERS
# These variables have defaults, but may be overridden by the operator.
# ---------------------------------------------------------------------------------------------------------------------

# Workaround terraform limitation where resource count can not include interpolated lists.
# See: https://github.com/hashicorp/terraform/issues/17421
variable "num_rbac_roles" {
  description = "Number of RBAC roles to bind. This should match the number of items in the list passed to rbac_roles."
  type        = number
  default     = 0
}

variable "rbac_roles" {
  description = "List of maps representing RBAC roles that should be bound to the service account. If this list is non-empty, you must also pass in num_rbac_roles specifying the number of roles. This expects a list of maps, each with keys name and namespace."
  type        = list(map(string))

  # Example:
  # rbac_roles = [{
  #   name      = "${module.namespace.rbac_access_read_only_role}"
  #   namespace = "${module.namespace.name}"
  # }]
  default = []
}

variable "labels" {
  description = "Map of string key default pairs that can be used to organize and categorize the service account. See the Kubernetes Reference for more info (https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)."
  type        = map(string)
  default     = {}
}

variable "annotations" {
  description = "Map of string key default pairs that can be used to store arbitrary metadata on the service account. See the Kubernetes Reference for more info (https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/)."
  type        = map(string)
  default     = {}
}

variable "automount_service_account_token" {
  description = "Whether or not to automatically mount the service account token into the container. This defaults to true."
  type        = bool
  default     = true
}

variable "secrets_for_pulling_images" {
  description = "A list of references to secrets in the same namespace to use for pulling any images in pods that reference this Service Account."
  type        = list(string)
  default     = []
}

variable "secrets_for_pods" {
  description = "A list of secrets allowed to be used by pods running using this Service Account."
  type        = list(string)
  default     = []
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
