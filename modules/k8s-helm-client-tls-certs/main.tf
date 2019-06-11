# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE TLS CERTS AND STORE THEM IN KUBERNETES SECRETS
# These templates generates a a signed TLS certificate key pair using CA certs stored in a Kubernetes Secret. These are
# then stored in Kubernetes Secrets so that they can be used to authenticate to Tiller.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ---------------------------------------------------------------------------------------------------------------------
# SET TERRAFORM REQUIREMENTS FOR RUNNING THIS MODULE
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 0.12"
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A TLS CERTIFICATE SIGNED USING THE CA CERTIFICATE
# ---------------------------------------------------------------------------------------------------------------------

resource "tls_private_key" "cert" {
  algorithm   = var.private_key_algorithm
  ecdsa_curve = var.private_key_ecdsa_curve
  rsa_bits    = var.private_key_rsa_bits
}

resource "tls_cert_request" "cert" {
  key_algorithm   = tls_private_key.cert.algorithm
  private_key_pem = tls_private_key.cert.private_key_pem

  dns_names    = var.tls_certs_dns_names
  ip_addresses = var.tls_certs_ip_addresses

  subject {
    common_name         = lookup(var.tls_subject, "common_name", null)
    organization        = lookup(var.tls_subject, "organization", null)
    organizational_unit = lookup(var.tls_subject, "organizational_unit", null)
    street_address      = local.tls_subject_maybe_street_address != "" ? split("\n", local.tls_subject_maybe_street_address) : []
    locality            = lookup(var.tls_subject, "locality", null)
    province            = lookup(var.tls_subject, "province", null)
    country             = lookup(var.tls_subject, "country", null)
    postal_code         = lookup(var.tls_subject, "postal_code", null)
    serial_number       = lookup(var.tls_subject, "serial_number", null)
  }
}

resource "tls_locally_signed_cert" "cert" {
  cert_request_pem = tls_cert_request.cert.cert_request_pem

  ca_key_algorithm = tls_private_key.cert.algorithm

  ca_private_key_pem = data.kubernetes_secret.ca_certs.data["${var.ca_tls_certificate_key_pair_secret_filename_base}.pem"]

  ca_cert_pem = data.kubernetes_secret.ca_certs.data["${var.ca_tls_certificate_key_pair_secret_filename_base}.crt"]

  validity_period_hours = var.validity_period_hours
  allowed_uses          = var.tls_certs_allowed_uses
}

locals {
  tls_subject_maybe_street_address = lookup(var.tls_subject, "street_address", "")
}

# ---------------------------------------------------------------------------------------------------------------------
# STORE SIGNED TLS CERTIFICATE IN KUBERNETES SECRET
# ---------------------------------------------------------------------------------------------------------------------

resource "kubernetes_secret" "signed_tls" {
  count = var.store_in_kubernetes_secret ? 1 : 0

  metadata {
    namespace   = var.tls_certificate_key_pair_secret_namespace
    name        = var.tls_certificate_key_pair_secret_name
    labels      = var.tls_certificate_key_pair_secret_labels
    annotations = var.tls_certificate_key_pair_secret_annotations
  }

  data = {
    "${var.tls_certificate_key_pair_secret_filename_base}.pem"    = tls_private_key.cert.private_key_pem
    "${var.tls_certificate_key_pair_secret_filename_base}.pub"    = tls_private_key.cert.public_key_pem
    "${var.tls_certificate_key_pair_secret_filename_base}.crt"    = tls_locally_signed_cert.cert.cert_pem
    "${var.ca_tls_certificate_key_pair_secret_filename_base}.crt" = data.kubernetes_secret.ca_certs.data["${var.ca_tls_certificate_key_pair_secret_filename_base}.crt"]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# DATA SOURCES
# ---------------------------------------------------------------------------------------------------------------------

# Lookup CA certificate info

data "kubernetes_secret" "ca_certs" {
  metadata {
    name      = var.ca_tls_certificate_key_pair_secret_name
    namespace = var.ca_tls_certificate_key_pair_secret_namespace
  }
}
