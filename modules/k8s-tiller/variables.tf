# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These variables are expected to be passed in by the operator when calling this terraform module.
# ---------------------------------------------------------------------------------------------------------------------

variable "namespace" {
  description = "The name of the Kubernetes Namespace where Tiller should be deployed into."
  type        = string
}

variable "tiller_service_account_name" {
  description = "The name of the Kubernetes ServiceAccount that Tiller should use when authenticating to the Kubernetes API."
  type        = string
}

variable "tiller_service_account_token_secret_name" {
  description = "The name of the Kubernetes Secret that holds the ServiceAccount token."
  type        = string
}

variable "tiller_tls_gen_method" {
  description = "The method in which the TLS certs for Tiller are generated. Must be one of `provider`, `kubergrunt`, or `none`."
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL MODULE PARAMETERS
# These variables have defaults, but may be overridden by the operator.
# ---------------------------------------------------------------------------------------------------------------------

variable "deployment_name" {
  description = "The name to use for the Kubernetes Deployment resource. This should be unique to the Namespace if you plan on having multiple Tiller Deployments in a single Namespace."
  type        = string
  default     = "tiller-deploy"
}

variable "deployment_labels" {
  description = "Any labels to attach to the Kubernetes Deployment resource."
  type        = map(string)
  default     = {}
}

variable "deployment_annotations" {
  description = "Any annotations to attach to the Kubernetes Deployment resource."
  type        = map(string)
  default     = {}
}

variable "deployment_replicas" {
  description = "The number of Pods to use for Tiller. 1 should be sufficient for most use cases."
  type        = number
  default     = 1
}

variable "service_name" {
  description = "The name to use for the Kubernetes Service resource. This should be unique to the Namespace if you plan on having multiple Tiller Deployments in a single Namespace."
  type        = string
  default     = "tiller-deploy"
}

variable "service_labels" {
  description = "Any labels to attach to the Kubernetes Service resource."
  type        = map(string)
  default     = {}
}

variable "service_annotations" {
  description = "Any annotations to attach to the Kubernetes Service resource."
  type        = map(string)
  default     = {}
}

variable "tiller_image" {
  description = "The container image to use for the Tiller Pods."
  type        = string
  default     = "gcr.io/kubernetes-helm/tiller"
}

variable "tiller_image_version" {
  description = "The version of the container image to use for the Tiller Pods."
  type        = string
  default     = "v2.11.0"
}

variable "tiller_image_pull_policy" {
  description = "Policy for pulling the container image used for the Tiller Pods. Use `Always` if the image tag is mutable (e.g latest)"
  type        = string
  default     = "IfNotPresent"
}

variable "tiller_listen_localhost" {
  description = "If Enabled, Tiller will only listen on localhost within the container."
  type        = bool
  default     = true
}

variable "tiller_history_max" {
  description = "The maximum number of revisions saved per release. Use 0 for no limit."
  type        = number
  default     = 0
}

variable "tiller_tls_key_file_name" {
  description = "The file name of the private key file for the server's TLS certificate key pair, as it is available in the Kubernetes Secret for the TLS certificates."
  type        = string
  default     = "tls.pem"
}

variable "tiller_tls_cert_file_name" {
  description = "The file name of the public certificate file for the server's TLS certificate key pair, as it is available in the Kubernetes Secret for the TLS certificates."
  type        = string
  default     = "tls.crt"
}

variable "tiller_tls_cacert_file_name" {
  description = "The file name of the CA certificate file that can be used to validate client side TLS certificates, as it is available in the Kubernetes Secret for the TLS certificates."
  type        = string
  default     = "ca.crt"
}

variable "tiller_tls_secret_name" {
  description = "The name of the Kubernetes Secret that holds the TLS certificate key pair to use for Tiller. Needs to provide the TLS private key, public certificate, and CA certificate to use for verifying client TLS certificate key pairs. Used when var.tiller_tls_gen_method = none."
  type        = string
  default     = null
}

variable "tiller_tls_subject" {
  description = "The issuer information that contains the identifying information for the Tiller server. Used to generate the TLS certificate keypairs. Used when var.tiller_tls_gen_method is not none. See https://www.terraform.io/docs/providers/tls/r/cert_request.html#common_name for a list of expected keys."
  type        = map(string)

  default = {
    common_name  = "tiller"
    organization = "Gruntwork"
  }
}

variable "private_key_algorithm" {
  description = "The name of the algorithm to use for private keys. Must be one of: RSA or ECDSA."
  type        = string
  default     = "ECDSA"
}

variable "private_key_ecdsa_curve" {
  description = "The name of the elliptic curve to use. Should only be used if var.private_key_algorithm is ECDSA. Must be one of P224, P256, P384 or P521."
  type        = string
  default     = "P256"
}

variable "private_key_rsa_bits" {
  description = "The size of the generated RSA key in bits. Should only be used if var.private_key_algorithm is RSA."
  type        = number
  default     = 2048
}

variable "tiller_tls_ca_cert_secret_namespace" {
  description = "The Kubernetes Namespace to use to store the CA certificate key pair."
  type        = string
  default     = "kube-system"
}

# kubergrunt and kubectl Authentication params

variable "kubectl_config_context_name" {
  description = "The config context to use when authenticating to the Kubernetes cluster. If empty, defaults to the current context specified in the kubeconfig file. Used when var.tiller_tls_gen_method is kubergrunt."
  type        = string
  default     = ""
}

variable "kubectl_config_path" {
  description = "The path to the config file to use for kubectl. If empty, defaults to $HOME/.kube/config. Used when var.tiller_tls_gen_method is kubergrunt."
  type        = string
  default     = ""
}

variable "kubectl_server_endpoint" {
  description = "The endpoint of the Kubernetes API to access when authenticating to the Kubernetes cluster. Use as an alternative to config and config context. When set, var.kubectl_ca_b64_data and var.kubectl_token must be provided. Used when var.tiller_tls_gen_method is kubergrunt."
  type        = string
  default     = ""
}

variable "kubectl_ca_b64_data" {
  description = "The bas64 encoded certificate authority of the Kubernetes API when authenticating to the Kubernetes cluster. Use as an alternative to config and config context. Must be set when var.kubectl_server_endpoint is not empty. Used when var.tiller_tls_gen_method is kubergrunt."
  type        = string
  default     = ""
}

variable "kubectl_token" {
  description = "The authentication token to use when authenticating to the Kubernetes cluster. Use as an alternative to config and config context. Must be set when var.kubectl_server_endpoint is not empty. Used when var.tiller_tls_gen_method is kubergrunt."
  type        = string
  default     = ""
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
