# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These variables are expected to be passed in by the operator
# ---------------------------------------------------------------------------------------------------------------------

variable "name" {
  description = "Name of the namespace to be created"
  type        = string
}

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

# ---------------------------------------------------------------------------------------------------------------------
# TEST PARAMETERS
# These variables are only used for testing purposes and should not be touched in normal operations.
# ---------------------------------------------------------------------------------------------------------------------

variable "create_resources" {
  description = "Set to false to have this module skip creating resources."
  type        = bool
  default     = true
}
