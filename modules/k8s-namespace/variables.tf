# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These variables are expected to be passed in by the operator when calling this terraform module.
# ---------------------------------------------------------------------------------------------------------------------

variable "name" {
  description = "The name of the namespace to be created."
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL MODULE PARAMETERS
# These variables have defaults, but may be overridden by the operator.
# ---------------------------------------------------------------------------------------------------------------------

variable "labels" {
  description = "Map of string key value pairs that can be used to organize and categorize the namespace and roles. See the Kubernetes Reference for more info (https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)."
  type        = "map"
  default     = {}
}

variable "annotations" {
  description = "Map of string key default pairs that can be used to store arbitrary metadata on the namespace and roles. See the Kubernetes Reference for more info (https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/)."
  type        = "map"
  default     = {}
}
