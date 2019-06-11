# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These variables are expected to be passed in by the operator
# ---------------------------------------------------------------------------------------------------------------------

variable "tiller_namespace" {
  description = "The namespace to deploy Tiller into."
  type        = string
}

variable "resource_namespace" {
  description = "The namespace where the Helm chart resources will be deployed into by Tiller."
  type        = string
}

variable "service_account_name" {
  description = "The name of the service account to use for Tiller."
  type        = string
}

variable "tls_subject" {
  description = "The issuer information that contains the identifying information for the Tiller server. Used to generate the TLS certificate keypairs."
  type        = map(string)

  default = {
    common_name = "tiller"
    org         = "Gruntwork"
  }
  # Expects the following keys
  # - common_name
  # - org
  # - org_unit
  # - city
  # - state
  # - country
}

variable "client_tls_subject" {
  description = "The issuer information that contains the identifying information for the helm client of the operator. Used to generate the TLS certificate keypairs."
  type        = map(string)

  default = {
    common_name = "admin"
    org         = "Gruntwork"
  }
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

# Tiller configuration

variable "tiller_version" {
  description = "The version of Tiller to deploy."
  type        = string
  default     = "v2.11.0"
}

# TLS algorithm configuration

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

# Kubectl options

variable "kubectl_config_context_name" {
  description = "The config context to use when authenticating to the Kubernetes cluster. If empty, defaults to the current context specified in the kubeconfig file."
  type        = string
  default     = ""
}

variable "kubectl_config_path" {
  description = "The path to the config file to use for kubectl. If empty, defaults to $HOME/.kube/config"
  type        = string
  default     = "~/.kube/config"
}

# Helm client config options

variable "configure_helm" {
  description = "Whether or not to configure the local helm client to authenticate to the deployed Tiller instance."
  type        = bool
  default     = true
}

variable "helm_home" {
  description = "The path to the home directory for helm that you wish to use for this deployment."
  type        = string
  default     = ""
}

variable "helm_client_rbac_user" {
  description = "If set, will setup the local helm client to authenticate using this RBAC user."
  type        = string
  default     = ""
}

variable "helm_client_rbac_group" {
  description = "If set, will setup the local helm client to authenticate using this RBAC group."
  type        = string
  default     = ""
}

variable "helm_client_rbac_service_account" {
  description = "If set, will setup the local helm client to authenticate using this ServiceAccount. The ServiceAccount should be encoded as NAMESPACE/NAME."
  type        = string
  default     = ""
}
