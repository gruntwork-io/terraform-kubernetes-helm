# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These variables are expected to be passed in by the operator when calling this terraform module.
# ---------------------------------------------------------------------------------------------------------------------

# TLS certificate information

variable "ca_tls_subject" {
  description = "The issuer information that contains the identifying information for the CA certificates. See https://www.terraform.io/docs/providers/tls/r/cert_request.html#common_name for a list of expected keys. Note that street_address must be a newline separated string as opposed to a list of strings."
  # We use an string type here instead of directly specifying the object, to allow certain keys to be optional.
  type = map(string)
}

variable "signed_tls_subject" {
  description = "The issuer information that contains the identifying information for the signed certificates. See https://www.terraform.io/docs/providers/tls/r/cert_request.html#common_name for a list of expected keys. Note that street_address must be a newline separated string as opposed to a list of strings."
  # We use an string type here instead of directly specifying the object, to allow certain keys to be optional.
  type = map(string)
}

# Kubernetes Secret information

variable "ca_tls_certificate_key_pair_secret_namespace" {
  description = "Namespace where the CA certificate key pairs should be stored."
  type        = string
}

variable "ca_tls_certificate_key_pair_secret_name" {
  description = "Name to use for the Secret resource that stores the CA certificate key pairs."
  type        = string
}

variable "signed_tls_certificate_key_pair_secret_namespace" {
  description = "Namespace where the signed TLS certificate key pairs should be stored."
  type        = string
}

variable "signed_tls_certificate_key_pair_secret_name" {
  description = "Name to use for the Secret resource that stores the signed TLS certificate key pairs."
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL MODULE PARAMETERS
# These variables have defaults, but may be overridden by the operator.
# ---------------------------------------------------------------------------------------------------------------------

# TLS certificate information

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

variable "ca_tls_certs_allowed_uses" {
  description = "List of keywords from RFC5280 describing a use that is permitted for the CA certificate. For more info and the list of keywords, see https://www.terraform.io/docs/providers/tls/r/self_signed_cert.html#allowed_uses."
  type        = list(string)

  default = [
    "cert_signing",
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
  ]
}

variable "signed_tls_certs_allowed_uses" {
  description = "List of keywords from RFC5280 describing a use that is permitted for the issued certificate. For more info and the list of keywords, see https://www.terraform.io/docs/providers/tls/r/self_signed_cert.html#allowed_uses."
  type        = list(string)

  default = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

variable "signed_tls_certs_dns_names" {
  description = "List of DNS names for which the certificate will be valid (e.g. tiller, foo.example.com)."
  type        = list(string)
  default     = []
}

variable "signed_tls_certs_ip_addresses" {
  description = "List of IP addresses for which the certificate will be valid (e.g. 127.0.0.1)."
  type        = list(string)
  default     = ["127.0.0.1"]
}

variable "validity_period_hours" {
  description = "The number of hours after initial issuing that the certificate will become invalid."
  type        = number

  # 10 years
  default = 87660
}

# Kubernetes Secret information

variable "ca_tls_certificate_key_pair_secret_filename_base" {
  description = "Basename to use for the TLS certificate files stored in the Secret."
  type        = string
  default     = "ca"
}

variable "ca_tls_certificate_key_pair_secret_labels" {
  description = "Labels to apply to the Secret resource that stores the CA certificate key pairs."
  type        = map(string)
  default     = {}
}

variable "ca_tls_certificate_key_pair_secret_annotations" {
  description = "Annotations to apply to the Secret resource that stores the CA certificate key pairs."
  type        = map(string)
  default     = {}
}

variable "signed_tls_certificate_key_pair_secret_filename_base" {
  description = "Basename to use for the signed TLS certificate files stored in the Secret."
  type        = string
  default     = "tls"
}

variable "signed_tls_certificate_key_pair_secret_labels" {
  description = "Labels to apply to the Secret resource that stores the signed TLS certificate key pairs."
  type        = map(string)
  default     = {}
}

variable "signed_tls_certificate_key_pair_secret_annotations" {
  description = "Annotations to apply to the Secret resource that stores the signed TLS certificate key pairs."
  type        = map(string)
  default     = {}
}

variable "create_resources" {
  description = "Set to false to have this module create no resources. This weird parameter exists solely because Terraform does not support conditional modules. Therefore, this is a hack to allow you to conditionally decide if the TLS certs should be created or not."
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
