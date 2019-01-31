# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These variables are expected to be passed in by the operator when calling this terraform module.
# ---------------------------------------------------------------------------------------------------------------------

variable "tiller_namespace" {
  description = "The namespace to deploy Tiller into."
}

variable "resource_namespace" {
  description = "The namespace to that Tiller manages (where the Helm chart resources will be deployed into)."
}

variable "service_account" {
  description = "The name of the service account to use for Tiller."
}

variable "tls_subject" {
  description = "The issuer information that contains the identifying information for the Tiller server. Used to generate the TLS certificate keypairs. common_name and org are required."
  type        = "map"

  # Expects the following keys
  # - common_name
  # - org
  # - org_unit
  # - city
  # - state
  # - country
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL MODULE PARAMETERS
# These variables have defaults, but may be overridden by the operator.
# ---------------------------------------------------------------------------------------------------------------------

variable "grant_access_to_rbac_users" {
  description = "The list of RBAC Users that should be granted access to the Tiller instance."
  type        = "list"
  default     = []
}

variable "grant_access_to_rbac_groups" {
  description = "The list of RBAC Groups that should be granted access to the Tiller instance."
  type        = "list"
  default     = []
}

variable "grant_access_to_rbac_service_accounts" {
  description = "The list of ServiceAccounts that should be granted access to the Tiller instance. The ServiceAccount should be encoded as NAMESPACE/NAME."
  type        = "list"
  default     = []
}

# TLS configuration

variable "private_key_algorithm" {
  description = "The name of the algorithm to use for private keys. Must be one of: RSA or ECDSA."
  default     = "ECDSA"
}

variable "private_key_ecdsa_curve" {
  description = "The name of the elliptic curve to use. Should only be used if var.private_key_algorithm is ECDSA. Must be one of P224, P256, P384 or P521."
  default     = "P256"
}

variable "private_key_rsa_bits" {
  description = "The size of the generated RSA key in bits. Should only be used if var.private_key_algorithm is RSA."
  default     = "2048"
}

# Kubernetes auth configuration

variable "kubectl_config_context_name" {
  description = "The config context to use when authenticating to the Kubernetes cluster. If empty, defaults to the current context specified in the kubeconfig file."
  default     = ""
}

variable "kubectl_config_path" {
  description = "The path to the config file to use for kubectl. If empty, defaults to $HOME/.kube/config"
  default     = ""
}

variable "helm_home" {
  description = "The path to the home directory for helm that you wish to use for this deployment."
  default     = ""
}

# Setup helm client. If any of the following is set, will setup the helm client with that entity.

variable "helm_client_rbac_user" {
  description = "If set, will setup the local helm client to authenticate using this RBAC user. The RBAC user must be in the grant_access_to_rbac_users list."
  default     = ""
}

variable "helm_client_rbac_group" {
  description = "If set, will setup the local helm client to authenticate using this RBAC group. The RBAC group must be in the grant_access_to_rbac_groups list."
  default     = ""
}

variable "helm_client_rbac_service_account" {
  description = "If set, will setup the local helm client to authenticate using this ServiceAccount. The ServiceAccount should be encoded as NAMESPACE/NAME. The ServiceAccount must be in the grant_access_to_rbac_service_accounts list."
  default     = ""
}

# Undeploy options

variable "force_undeploy" {
  description = "If true, will remove the Tiller server resources even if there are releases deployed."
  default     = false
}

variable "undeploy_releases" {
  description = "If true, will delete deployed releases from the Tiller instance before undeploying Tiller."
  default     = false
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE DEPENDENCIES
# Workaround Terraform limitation where there is no module depends_on.
# See https://github.com/hashicorp/terraform/issues/1178 for more details.
# ---------------------------------------------------------------------------------------------------------------------

variable "dependencies" {
  description = "Create a dependency between the resources in this module to the interpolated values in this list (and thus the source resources). In other words, the resources in this module will now depend on the resources backing the values in this list such that those resources need to be created before the resources in this module, and the resources in this module need to be destroyed before the resources in the list."
  type        = "list"
  default     = []
}
