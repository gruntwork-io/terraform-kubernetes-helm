variable "namespace" {
  description = "The namespace to deploy the helm server into."
}

variable "service_account" {
  description = "The name of the service account to use for the helm server."
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

variable "ca_certificate_rbac_roles" {
  description = "The RBAC roles that should be granted access to the CA certificate keypair."
  type        = "list"
  default     = []
}

variable "tiller_certificate_rbac_roles" {
  description = "The RBAC roles that should be granted access to the certificate keypair used by the Tiller server."
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
