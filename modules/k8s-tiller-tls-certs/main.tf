# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE TLS CERTS AND STORE THEM IN KUBERNETES SECRETS
# These templates generates a CA TLS certificate key pairs, and then uses that to generate a signed TLS certificate key
# pair. These are then stored in Kubernetes Secrets so that they can be used with applications that support TLS, like
# Tiller.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ---------------------------------------------------------------------------------------------------------------------
# SET TERRAFORM REQUIREMENTS FOR RUNNING THIS MODULE
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = "~> 0.9"
}

# ---------------------------------------------------------------------------------------------------------------------
#  CREATE A CA CERTIFICATE
# ---------------------------------------------------------------------------------------------------------------------

resource "tls_private_key" "ca" {
  algorithm   = "${var.private_key_algorithm}"
  ecdsa_curve = "${var.private_key_ecdsa_curve}"
  rsa_bits    = "${var.private_key_rsa_bits}"
}

resource "tls_self_signed_cert" "ca" {
  key_algorithm     = "${tls_private_key.ca.algorithm}"
  private_key_pem   = "${tls_private_key.ca.private_key_pem}"
  is_ca_certificate = true

  validity_period_hours = "${var.validity_period_hours}"
  allowed_uses          = ["${var.ca_tls_certs_allowed_uses}"]

  subject = ["${var.ca_tls_subject}"]
}

# ---------------------------------------------------------------------------------------------------------------------
# STORE CA CERTIFICATE IN KUBERNETES SECRET
# ---------------------------------------------------------------------------------------------------------------------

resource "kubernetes_secret" "ca_secret" {
  metadata {
    namespace   = "${var.ca_tls_certificate_key_pair_secret_namespace}"
    name        = "${var.ca_tls_certificate_key_pair_secret_name}"
    labels      = "${var.ca_tls_certificate_key_pair_secret_labels}"
    annotations = "${var.ca_tls_certificate_key_pair_secret_annotations}"
  }

  data = "${
    map(
      "${var.ca_tls_certificate_key_pair_secret_filename_base}.pem", "${tls_private_key.ca.private_key_pem}",
      "${var.ca_tls_certificate_key_pair_secret_filename_base}.pub", "${tls_private_key.ca.public_key_pem}",
      "${var.ca_tls_certificate_key_pair_secret_filename_base}.crt", "${tls_self_signed_cert.ca.cert_pem}",
    )
  }"
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A TLS CERTIFICATE SIGNED USING THE CA CERTIFICATE
# ---------------------------------------------------------------------------------------------------------------------

resource "tls_private_key" "cert" {
  algorithm   = "${var.private_key_algorithm}"
  ecdsa_curve = "${var.private_key_ecdsa_curve}"
  rsa_bits    = "${var.private_key_rsa_bits}"
}

resource "tls_cert_request" "cert" {
  key_algorithm   = "${tls_private_key.cert.algorithm}"
  private_key_pem = "${tls_private_key.cert.private_key_pem}"

  dns_names    = ["${var.signed_tls_certs_dns_names}"]
  ip_addresses = ["${var.signed_tls_certs_ip_addresses}"]

  subject = ["${var.signed_tls_subject}"]
}

resource "tls_locally_signed_cert" "cert" {
  cert_request_pem = "${tls_cert_request.cert.cert_request_pem}"

  ca_key_algorithm   = "${tls_private_key.ca.algorithm}"
  ca_private_key_pem = "${tls_private_key.ca.private_key_pem}"
  ca_cert_pem        = "${tls_self_signed_cert.ca.cert_pem}"

  validity_period_hours = "${var.validity_period_hours}"
  allowed_uses          = ["${var.signed_tls_certs_allowed_uses}"]
}

# ---------------------------------------------------------------------------------------------------------------------
# STORE SIGNED TLS CERTIFICATE IN KUBERNETES SECRET
# ---------------------------------------------------------------------------------------------------------------------

resource "kubernetes_secret" "signed_tls" {
  metadata {
    namespace   = "${var.signed_tls_certificate_key_pair_secret_namespace}"
    name        = "${var.signed_tls_certificate_key_pair_secret_name}"
    labels      = "${var.signed_tls_certificate_key_pair_secret_labels}"
    annotations = "${var.signed_tls_certificate_key_pair_secret_annotations}"
  }

  data = "${
    map(
      "${var.signed_tls_certificate_key_pair_secret_filename_base}.pem", "${tls_private_key.cert.private_key_pem}",
      "${var.signed_tls_certificate_key_pair_secret_filename_base}.pub", "${tls_private_key.cert.public_key_pem}",
      "${var.signed_tls_certificate_key_pair_secret_filename_base}.crt", "${tls_locally_signed_cert.cert.cert_pem}",
      "${var.ca_tls_certificate_key_pair_secret_filename_base}.crt", "${tls_self_signed_cert.ca.cert_pem}",
    )
  }"
}
