# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These variables are expected to be passed in by the operator when calling this terraform module.
# ---------------------------------------------------------------------------------------------------------------------

# TLS certificate information

variable "tls_subject" {
  description = "The issuer information that contains the identifying information for the signed certificates. See https://www.terraform.io/docs/providers/tls/r/cert_request.html#common_name for a list of expected keys. Note that street_address must be a newline separated string as opposed to a list of strings."
  # We use an string type here instead of directly specifying the object, to allow certain keys to be optional.
  type = map(string)
}

# Kubernetes Secret information

variable "ca_tls_certificate_key_pair_secret_namespace" {
  description = "Namespace where the CA certificate key pairs are stored."
  type        = string
}

variable "ca_tls_certificate_key_pair_secret_name" {
  description = "Name to use for the Secret resource that stores the CA certificate key pairs."
  type        = string
}

variable "tls_certificate_key_pair_secret_namespace" {
  description = "Namespace where the signed TLS certificate key pairs should be stored."
  type        = string
}

variable "tls_certificate_key_pair_secret_name" {
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

variable "tls_certs_allowed_uses" {
  description = "List of keywords from RFC5280 describing a use that is permitted for the issued certificate. For more info and the list of keywords, see https://www.terraform.io/docs/providers/tls/r/self_signed_cert.html#allowed_uses."
  type        = list(string)

  default = [
    "key_encipherment",
    "digital_signature",
    "client_auth",
  ]
}

variable "tls_certs_dns_names" {
  description = "List of DNS names for which the certificate will be valid (e.g. tiller, foo.example.com)."
  type        = list(string)
  default     = []
}

variable "tls_certs_ip_addresses" {
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

variable "store_in_kubernetes_secret" {
  description = "Whether or not to store the generated TLS certificate key pairs in Kubernetes Secret."
  type        = bool
  default     = true
}

variable "ca_tls_certificate_key_pair_secret_filename_base" {
  description = "Basename used for the TLS certificate files stored in the Secret."
  type        = string
  default     = "ca"
}

variable "tls_certificate_key_pair_secret_filename_base" {
  description = "Basename to use for the signed TLS certificate files stored in the Secret."
  type        = string
  default     = "client"
}

variable "tls_certificate_key_pair_secret_labels" {
  description = "Labels to apply to the Secret resource that stores the signed TLS certificate key pairs."
  type        = map(string)
  default     = {}
}

variable "tls_certificate_key_pair_secret_annotations" {
  description = "Annotations to apply to the Secret resource that stores the signed TLS certificate key pairs."
  type        = map(string)
  default     = {}
}
