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
  description = "The list of ServiceAccounts that should be granted access to the Tiller instance."
  type        = "list"
  default     = []
}

variable "kubectl_config_context_name" {
  description = "The config context to use when authenticating to the Kubernetes cluster. If empty, defaults to the current context specified in the kubeconfig file."
  value       = ""
}

variable "kubectl_config_path" {
  description = "The path to the config file to use for kubectl. If empty, defaults to $HOME/.kube/config"
  value       = ""
}
