# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These variables are expected to be passed in by the operator
# ---------------------------------------------------------------------------------------------------------------------

variable "tiller_namespace" {
  description = "The namespace to deploy Tiller into."
}

variable "resource_namespace" {
  description = "The namespace to that Tiller manages (where the Helm chart resources will be deployed into)."
}

variable "service_account_name" {
  description = "The name of the service account to use for Tiller."
}

variable "tls_subject" {
  description = "The issuer information that contains the identifying information for the Tiller server. Used to generate the TLS certificate keypairs."
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
# These variables have reasonable defaults,  but can be overridden.
# ---------------------------------------------------------------------------------------------------------------------

variable "kubectl_config_context_name" {
  description = "The config context to use when authenticating to the Kubernetes cluster. If empty, defaults to the current context specified in the kubeconfig file."
  default     = ""
}

variable "kubectl_config_path" {
  description = "The path to the config file to use for kubectl. If empty, defaults to $HOME/.kube/config"
  default     = "~/.kube/config"
}

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

variable "helm_home" {
  description = "The path to the home directory for helm that you wish to use for this deployment."
  default     = ""
}

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
