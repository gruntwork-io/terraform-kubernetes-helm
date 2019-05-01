# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These variables are expected to be passed in by the operator when calling this terraform module.
# ---------------------------------------------------------------------------------------------------------------------

variable "namespace" {
  description = "The name of the Kubernetes Namespace where Tiller should be deployed into."
}

variable "tiller_service_account_name" {
  description = "The name of the Kubernetes ServiceAccount that Tiller should use when authenticating to the Kubernetes API."
}

variable "tiller_service_account_token_secret_name" {
  description = "The name of the Kubernetes Secret that holds the ServiceAccount token."
}

variable "tiller_tls_secret_name" {
  description = "The name of the Kubernetes Secret that holds the TLS certificate key pair to use for Tiller. Needs to provide the TLS private key, public certificate, and CA certificate to use for verifying client TLS certificate key pairs."
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL MODULE PARAMETERS
# These variables have defaults, but may be overridden by the operator.
# ---------------------------------------------------------------------------------------------------------------------

variable "deployment_name" {
  description = "The name to use for the Kubernetes Deployment resource. This should be unique to the Namespace if you plan on having multiple Tiller Deployments in a single Namespace."
  default     = "tiller-deploy"
}

variable "deployment_labels" {
  description = "Any labels to attach to the Kubernetes Deployment resource."
  type        = "map"
  default     = {}
}

variable "deployment_annotations" {
  description = "Any annotations to attach to the Kubernetes Deployment resource."
  type        = "map"
  default     = {}
}

variable "deployment_replicas" {
  description = "The number of Pods to use for Tiller. 1 should be sufficient for most use cases."
  default     = 1
}

variable "service_name" {
  description = "The name to use for the Kubernetes Service resource. This should be unique to the Namespace if you plan on having multiple Tiller Deployments in a single Namespace."
  default     = "tiller-deploy"
}

variable "service_labels" {
  description = "Any labels to attach to the Kubernetes Service resource."
  type        = "map"
  default     = {}
}

variable "service_annotations" {
  description = "Any annotations to attach to the Kubernetes Service resource."
  type        = "map"
  default     = {}
}

variable "tiller_tls_key_file_name" {
  description = "The file name of the private key file for the server's TLS certificate key pair, as it is available in the Kubernetes Secret for the TLS certificates."
  default     = "tls.key"
}

variable "tiller_tls_cert_file_name" {
  description = "The file name of the public certificate file for the server's TLS certificate key pair, as it is available in the Kubernetes Secret for the TLS certificates."
  default     = "tls.crt"
}

variable "tiller_tls_cacert_file_name" {
  description = "The file name of the CA certificate file that can be used to validate client side TLS certificates, as it is available in the Kubernetes Secret for the TLS certificates."
  default     = "ca.crt"
}

variable "tiller_image" {
  description = "The container image to use for the Tiller Pods."
  default     = "gcr.io/kubernetes-helm/tiller"
}

variable "tiller_image_version" {
  description = "The version of the container image to use for the Tiller Pods."
  default     = "v2.11.0"
}

variable "tiller_image_pull_policy" {
  description = "Policy for pulling the container image used for the Tiller Pods. Use `Always` if the image tag is mutable (e.g latest)"
  default     = "IfNotPresent"
}

variable "tiller_history_max" {
  description = "The maximum number of revisions saved per release. Use 0 for no limit."
  default     = 0
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
# wait_for = ["${kubernetes_cluster_role_binding.user.metadata.0.name}"]
# ---------------------------------------------------------------------------------------------------------------------

variable "wait_for" {
  description = "Create a dependency between the resources in this module to the interpolated values in this list (and thus the source resources). In other words, the resources in this module will now depend on the resources backing the values in this list such that those resources need to be created before the resources in this module, and the resources in this module need to be destroyed before the resources in the list."
  type        = "list"
  default     = []
}
