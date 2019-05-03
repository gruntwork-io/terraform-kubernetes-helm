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
# SET MODULE DEPENDENCY RESOURCE
# This works around a terraform limitation where we can not specify module dependencies natively.
# See https://github.com/hashicorp/terraform/issues/1178 for more discussion.
# By resolving and computing the dependencies list, we are able to make all the resources in this module depend on the
# resources backing the values in the dependencies list.
# ---------------------------------------------------------------------------------------------------------------------

resource "null_resource" "dependency_getter" {
  triggers = {
    instance = "${join(",", var.dependencies)}"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
#  CREATE A CA CERTIFICATE
# ---------------------------------------------------------------------------------------------------------------------

resource "tls_private_key" "ca" {
  count      = "${var.create_resources ? 1 : 0}"
  depends_on = ["null_resource.dependency_getter"]

  algorithm   = "${var.private_key_algorithm}"
  ecdsa_curve = "${var.private_key_ecdsa_curve}"
  rsa_bits    = "${var.private_key_rsa_bits}"
}

resource "tls_self_signed_cert" "ca" {
  count      = "${var.create_resources ? 1 : 0}"
  depends_on = ["null_resource.dependency_getter"]

  key_algorithm     = "${element(concat(tls_private_key.ca.*.algorithm, list("")), 0)}"
  private_key_pem   = "${element(concat(tls_private_key.ca.*.private_key_pem, list("")), 0)}"
  is_ca_certificate = true

  validity_period_hours = "${var.validity_period_hours}"
  allowed_uses          = ["${var.ca_tls_certs_allowed_uses}"]

  subject = ["${var.ca_tls_subject}"]
}

# ---------------------------------------------------------------------------------------------------------------------
# STORE CA CERTIFICATE IN KUBERNETES SECRET
# ---------------------------------------------------------------------------------------------------------------------

resource "kubernetes_secret" "ca_secret" {
  count      = "${var.create_resources ? 1 : 0}"
  depends_on = ["null_resource.dependency_getter"]

  metadata {
    namespace   = "${var.ca_tls_certificate_key_pair_secret_namespace}"
    name        = "${var.ca_tls_certificate_key_pair_secret_name}"
    labels      = "${var.ca_tls_certificate_key_pair_secret_labels}"
    annotations = "${var.ca_tls_certificate_key_pair_secret_annotations}"
  }

  data = "${
    map(
      "${var.ca_tls_certificate_key_pair_secret_filename_base}.pem", "${element(concat(tls_private_key.ca.*.private_key_pem, list("")), 0)}",
      "${var.ca_tls_certificate_key_pair_secret_filename_base}.pub", "${element(concat(tls_private_key.ca.*.public_key_pem, list("")), 0)}",
      "${var.ca_tls_certificate_key_pair_secret_filename_base}.crt", "${element(concat(tls_self_signed_cert.ca.*.cert_pem, list("")), 0)}",
    )
  }"
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A TLS CERTIFICATE SIGNED USING THE CA CERTIFICATE
# ---------------------------------------------------------------------------------------------------------------------

resource "tls_private_key" "cert" {
  count      = "${var.create_resources ? 1 : 0}"
  depends_on = ["null_resource.dependency_getter"]

  algorithm   = "${var.private_key_algorithm}"
  ecdsa_curve = "${var.private_key_ecdsa_curve}"
  rsa_bits    = "${var.private_key_rsa_bits}"
}

resource "tls_cert_request" "cert" {
  count = "${var.create_resources ? 1 : 0}"

  key_algorithm   = "${element(concat(tls_private_key.cert.*.algorithm, list("")), 0)}"
  private_key_pem = "${element(concat(tls_private_key.cert.*.private_key_pem, list("")), 0)}"

  dns_names    = ["${var.signed_tls_certs_dns_names}"]
  ip_addresses = ["${var.signed_tls_certs_ip_addresses}"]

  subject = ["${var.signed_tls_subject}"]
}

resource "tls_locally_signed_cert" "cert" {
  count      = "${var.create_resources ? 1 : 0}"
  depends_on = ["null_resource.dependency_getter"]

  cert_request_pem = "${element(concat(tls_cert_request.cert.*.cert_request_pem, list("")), 0)}"

  ca_key_algorithm   = "${element(concat(tls_private_key.ca.*.algorithm, list("")), 0)}"
  ca_private_key_pem = "${element(concat(tls_private_key.ca.*.private_key_pem, list("")), 0)}"
  ca_cert_pem        = "${element(concat(tls_self_signed_cert.ca.*.cert_pem, list("")), 0)}"

  validity_period_hours = "${var.validity_period_hours}"
  allowed_uses          = ["${var.signed_tls_certs_allowed_uses}"]
}

# ---------------------------------------------------------------------------------------------------------------------
# STORE SIGNED TLS CERTIFICATE IN KUBERNETES SECRET
# ---------------------------------------------------------------------------------------------------------------------

resource "kubernetes_secret" "signed_tls" {
  count      = "${var.create_resources ? 1 : 0}"
  depends_on = ["null_resource.dependency_getter"]

  metadata {
    namespace   = "${var.signed_tls_certificate_key_pair_secret_namespace}"
    name        = "${var.signed_tls_certificate_key_pair_secret_name}"
    labels      = "${var.signed_tls_certificate_key_pair_secret_labels}"
    annotations = "${var.signed_tls_certificate_key_pair_secret_annotations}"
  }

  data = "${
    map(
      "${var.signed_tls_certificate_key_pair_secret_filename_base}.pem", "${element(concat(tls_private_key.cert.*.private_key_pem, list("")), 0)}",
      "${var.signed_tls_certificate_key_pair_secret_filename_base}.pub", "${element(concat(tls_private_key.cert.*.public_key_pem, list("")), 0)}",
      "${var.signed_tls_certificate_key_pair_secret_filename_base}.crt", "${element(concat(tls_locally_signed_cert.cert.*.cert_pem, list("")), 0)}",
      "${var.ca_tls_certificate_key_pair_secret_filename_base}.crt", "${element(concat(tls_self_signed_cert.ca.*.cert_pem, list("")), 0)}",
    )
  }"
}
