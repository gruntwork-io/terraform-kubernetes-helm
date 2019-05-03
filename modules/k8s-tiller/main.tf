# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE DEPLOYMENT AND SERVICE RESOURCES FOR MANAGING TILLER
# These templates provision a new Kubernetes deployment that manages the Tiller Pods with all the security features
# turned on. This includes:
# - TLS verification and authentication
# - Using Secrets to store the release info.
# - Only listening on localhost within the container.
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
# CREATE THE DEPLOYMENT RESOURCE
# ---------------------------------------------------------------------------------------------------------------------

# Adapted from Tiller installer in helm client. See:
# https://github.com/helm/helm/blob/master/cmd/helm/installer/install.go#L200
resource "kubernetes_deployment" "tiller" {
  depends_on = [
    "null_resource.dependency_getter",
    "null_resource.tls_secret_generated",
    "null_resource.tiller_tls_certs",
  ]

  metadata {
    namespace   = "${var.namespace}"
    name        = "${var.deployment_name}"
    annotations = "${var.deployment_annotations}"

    # The labels app=helm and name=tiller need to be added for helm client to work.
    labels = "${merge(
      map(
        "app", "helm",
        "name", "tiller",
      ),
      var.deployment_labels
    )}"
  }

  spec {
    replicas = "${var.deployment_replicas}"

    # Only manage the Tiller pods deployed by this deployment
    selector {
      match_labels {
        app        = "helm"
        name       = "tiller"
        deployment = "${var.deployment_name}"
      }
    }

    template {
      metadata {
        labels {
          app        = "helm"
          name       = "tiller"
          deployment = "${var.deployment_name}"
        }
      }

      spec {
        service_account_name = "${var.tiller_service_account_name}"

        container {
          name              = "tiller"
          image             = "${var.tiller_image}:${var.tiller_image_version}"
          image_pull_policy = "${var.tiller_image_pull_policy}"
          command           = ["/tiller"]

          args = [
            # Use Secrets for storing release info, which contain the values.yaml file info.
            "--storage=secret",

            # Set to only listen on localhost so that it is only available via port-forwarding. The helm client (and terraform
            # helm provider) use port-forwarding to communicate with Tiller so this is a safer default.
            "--listen=localhost:44134",

            # Since the Secret for the TLS certs aren't created by helm init, allow user to override the file names.
            "--tls-key=${local.tls_certs_mount_path}/${var.tiller_tls_key_file_name}",

            "--tls-cert=${local.tls_certs_mount_path}/${var.tiller_tls_cert_file_name}",
            "--tls-ca-cert=${local.tls_certs_mount_path}/${var.tiller_tls_cacert_file_name}",
          ]

          env {
            name  = "TILLER_NAMESPACE"
            value = "${var.namespace}"
          }

          env {
            name  = "TILLER_HISTORY_MAX"
            value = "${var.tiller_history_max}"
          }

          env {
            name  = "TILLER_TLS_VERIFY"
            value = "1"
          }

          env {
            name  = "TILLER_TLS_ENABLE"
            value = "1"
          }

          env {
            name  = "TILLER_TLS_CERTS"
            value = "/etc/certs"
          }

          # Port for accessing Tiller
          port {
            container_port = 44134
            name           = "tiller"
          }

          # Port for health checks
          port {
            container_port = 44135
            name           = "http"
          }

          liveness_probe {
            http_get {
              path = "/liveness"
              port = 44135
            }

            initial_delay_seconds = 1
            timeout_seconds       = 1
          }

          readiness_probe {
            http_get {
              path = "/readiness"
              port = 44135
            }

            initial_delay_seconds = 1
            timeout_seconds       = 1
          }

          # Make sure to mount the ServiceAccount token.
          volume_mount {
            mount_path = "${local.service_account_token_mount_path}"
            name       = "${var.tiller_service_account_token_secret_name}"
            read_only  = true
          }

          # Mount the TLS certs into the location Tiller expects
          volume_mount {
            mount_path = "${local.tls_certs_mount_path}"
            name       = "${local.tls_secret_volume_name}"
            read_only  = true
          }

          # end container
        }

        # We have to mount the service account token so that Tiller can access the Kubernetes API as the attached
        # ServiceAccount.
        volume {
          name = "${var.tiller_service_account_token_secret_name}"

          secret {
            secret_name = "${var.tiller_service_account_token_secret_name}"
          }
        }

        # Mount the volume for the TLS secrets
        volume {
          name = "${local.tls_secret_volume_name}"

          secret {
            secret_name = "${local.generated_tls_secret_name}"
          }
        }

        # end template spec
      }

      # end template
    }

    # end spec
  }

  # end deployment
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE SERVICE RESOURCE TO FRONT THE DEPLOYMENT
# ---------------------------------------------------------------------------------------------------------------------

# Adapted from Tiller installer in helm client. See:
# https://github.com/helm/helm/blob/master/cmd/helm/installer/install.go#L332
resource "kubernetes_service" "tiller" {
  depends_on = ["null_resource.dependency_getter"]

  metadata {
    namespace   = "${var.namespace}"
    name        = "${var.service_name}"
    annotations = "${var.service_annotations}"

    # The labels app=helm and name=tiller need to be added for helm client to work.
    labels = "${merge(
      map(
        "app", "helm",
        "name", "tiller",
      ),
      var.service_labels
    )}"
  }

  spec {
    type = "ClusterIP"

    port {
      name        = "tiller"
      port        = 44134
      target_port = "tiller"
    }

    selector {
      app        = "helm"
      name       = "tiller"
      deployment = "${var.deployment_name}"
    }
  }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# [KUBERGRUNT] GENERATE TLS CERTIFICATES FOR USE WITH TILLER
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Generate CA TLS certs
resource "null_resource" "tiller_tls_ca_certs" {
  count      = "${var.tiller_tls_gen_method == "kubergrunt" ? 1 : 0}"
  depends_on = ["null_resource.dependency_getter"]

  provisioner "local-exec" {
    command = <<-EOF
    ${lookup(module.require_executables.executables, "kubergrunt", "")} tls gen ${local.esc_newl}
      ${local.kubergrunt_auth_params} ${local.esc_newl}
      --ca ${local.esc_newl}
      --namespace ${var.tiller_tls_ca_cert_secret_namespace} ${local.esc_newl}
      --secret-name ${local.tiller_tls_ca_certs_secret_name} ${local.esc_newl}
      --secret-label gruntwork.io/tiller-namespace=${var.namespace} ${local.esc_newl}
      --secret-label gruntwork.io/tiller-credentials=true ${local.esc_newl}
      --secret-label gruntwork.io/tiller-credentials-type=ca ${local.esc_newl}
      --tls-subject-json '${jsonencode(local.tiller_tls_ca_certs_subject)}' ${local.esc_newl}
      --tls-private-key-algorithm ${var.private_key_algorithm} ${local.esc_newl}
      ${local.tls_algorithm_config}
    EOF

    # Use environment variables for Kubernetes credentials to avoid leaking into the logs
    environment = {
      KUBECTL_SERVER_ENDPOINT = "${var.kubectl_server_endpoint}"
      KUBECTL_CA_DATA         = "${var.kubectl_ca_b64_data}"
      KUBECTL_TOKEN           = "${var.kubectl_token}"
    }
  }

  provisioner "local-exec" {
    when = "destroy"

    command = <<-EOF
    ${var.kubectl_server_endpoint != "" ? "echo \"$KUBECTL_CA_DATA\" > ${path.module}/kubernetes_server_ca.pem" : ""}
    ${lookup(module.require_executables.executables, "kubectl", "")} ${local.esc_newl}
      ${local.kubectl_auth_params} ${local.esc_newl}
      --namespace ${var.tiller_tls_ca_cert_secret_namespace} ${local.esc_newl}
      delete secret ${local.tiller_tls_ca_certs_secret_name}
    EOF

    # Use environment variables for Kubernetes credentials to avoid leaking into the logs
    environment = {
      KUBECTL_SERVER_ENDPOINT = "${var.kubectl_server_endpoint}"
      KUBECTL_CA_DATA         = "${base64decode(var.kubectl_ca_b64_data)}"
      KUBECTL_TOKEN           = "${var.kubectl_token}"
    }
  }
}

# Use generated CA certs to create new certs for server
resource "null_resource" "tiller_tls_certs" {
  count      = "${var.tiller_tls_gen_method == "kubergrunt" ? 1 : 0}"
  depends_on = ["null_resource.dependency_getter"]

  triggers {
    ca_cert_create_action = "${element(concat(null_resource.tiller_tls_ca_certs.*.id, list("")), 0)}"
  }

  provisioner "local-exec" {
    command = <<-EOF
    ${lookup(module.require_executables.executables, "kubergrunt", "")} tls gen ${local.esc_newl}
      ${local.kubergrunt_auth_params} ${local.esc_newl}
      --namespace ${var.namespace} ${local.esc_newl}
      --ca-secret-name ${local.tiller_tls_ca_certs_secret_name} ${local.esc_newl}
      --ca-namespace  ${var.tiller_tls_ca_cert_secret_namespace} ${local.esc_newl}
      --secret-name ${local.tiller_tls_certs_secret_name} ${local.esc_newl}
      --secret-label gruntwork.io/tiller-namespace=${var.namespace} ${local.esc_newl}
      --secret-label gruntwork.io/tiller-credentials=true ${local.esc_newl}
      --secret-label gruntwork.io/tiller-credentials-type=server ${local.esc_newl}
      --tls-subject-json '${jsonencode(var.tiller_tls_subject)}' ${local.esc_newl}
      --tls-private-key-algorithm ${var.private_key_algorithm} ${local.esc_newl}
      ${local.tls_algorithm_config}
    EOF

    # Use environment variables for Kubernetes credentials to avoid leaking into the logs
    environment = {
      KUBECTL_SERVER_ENDPOINT = "${var.kubectl_server_endpoint}"
      KUBECTL_CA_DATA         = "${var.kubectl_ca_b64_data}"
      KUBECTL_TOKEN           = "${var.kubectl_token}"
    }
  }

  provisioner "local-exec" {
    when = "destroy"

    command = <<-EOF
    ${var.kubectl_server_endpoint != "" ? "echo \"$KUBECTL_CA_DATA\" > ${path.module}/kubernetes_server_ca.pem" : ""}
    ${lookup(module.require_executables.executables, "kubectl", "")} ${local.esc_newl}
      ${local.kubectl_auth_params} ${local.esc_newl}
      --namespace ${var.namespace} ${local.esc_newl}
      delete secret ${local.tiller_tls_certs_secret_name}
    EOF

    # Use environment variables for Kubernetes credentials to avoid leaking into the logs
    environment = {
      KUBECTL_SERVER_ENDPOINT = "${var.kubectl_server_endpoint}"
      KUBECTL_CA_DATA         = "${base64decode(var.kubectl_ca_b64_data)}"
      KUBECTL_TOKEN           = "${var.kubectl_token}"
    }
  }
}

module "require_executables" {
  source = "git::git@github.com:gruntwork-io/package-terraform-utilities.git//modules/require-executable?ref=v0.0.8"

  required_executables = ["${var.tiller_tls_gen_method == "kubergrunt" ? list("kubergrunt", "kubectl") : list("")}"]
  error_message        = "The __EXECUTABLE_NAME__ binary is not available in your PATH. Install the binary by following the instructions at https://github.com/gruntwork-io/terraform-kubernetes-helm/blob/master/modules/k8s-tiller/README.md#generating-with-kubergrunt, or update your PATH variable to search where you installed __EXECUTABLE_NAME__."
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# [PROVIDER] GENERATE TLS CERTIFICATES FOR USE WITH TILLER
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

module "tiller_tls_certs" {
  source = "../k8s-tiller-tls-certs"

  ca_tls_subject = "${local.tiller_tls_ca_certs_subject}"

  ca_tls_certificate_key_pair_secret_namespace = "${var.tiller_tls_ca_cert_secret_namespace}"
  ca_tls_certificate_key_pair_secret_name      = "${local.tiller_tls_ca_certs_secret_name}"

  ca_tls_certificate_key_pair_secret_labels = {
    "gruntwork.io/tiller-namespace"        = "${var.namespace}"
    "gruntwork.io/tiller-credentials"      = "true"
    "gruntwork.io/tiller-credentials-type" = "ca"
  }

  signed_tls_subject                               = "${var.tiller_tls_subject}"
  signed_tls_certificate_key_pair_secret_namespace = "${var.namespace}"
  signed_tls_certificate_key_pair_secret_name      = "${local.tiller_tls_certs_secret_name}"

  signed_tls_certificate_key_pair_secret_labels = {
    "gruntwork.io/tiller-namespace"        = "${var.namespace}"
    "gruntwork.io/tiller-credentials"      = "true"
    "gruntwork.io/tiller-credentials-type" = "server"
  }

  private_key_algorithm   = "${var.private_key_algorithm}"
  private_key_ecdsa_curve = "${var.private_key_ecdsa_curve}"
  private_key_rsa_bits    = "${var.private_key_rsa_bits}"

  create_resources = "${var.tiller_tls_gen_method == "provider"}"
  dependencies     = ["${null_resource.dependency_getter.id}"]
}

resource "null_resource" "tls_secret_generated" {
  count = "${var.tiller_tls_gen_method == "provider" ? 1 : 0}"

  triggers = {
    instance = "${module.tiller_tls_certs.signed_tls_certificate_key_pair_secret_name}"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# GLOBAL CONSTANTS
# Avoids the usage of magic strings.
# ---------------------------------------------------------------------------------------------------------------------

locals {
  service_account_token_mount_path = "/var/run/secrets/kubernetes.io/serviceaccount"
  tls_certs_mount_path             = "/etc/certs"
  tls_secret_volume_name           = "tiller-certs"
}

# ---------------------------------------------------------------------------------------------------------------------
# COMPUTATIONS
# Intermediate computations of various flags
# ---------------------------------------------------------------------------------------------------------------------

locals {
  generated_tls_secret_name = "${
    var.tiller_tls_gen_method == "none"
    ? var.tiller_tls_secret_name
    : local.tiller_tls_certs_secret_name
  }"

  tiller_tls_ca_certs_subject = "${
    merge(
      var.tiller_tls_subject,
      map("common_name", "${lookup(var.tiller_tls_subject, "common_name")} CA"),
    )
  }"

  tiller_tls_ca_certs_secret_name = "${var.namespace}-namespace-tiller-ca-certs"
  tiller_tls_certs_secret_name    = "${var.namespace}-namespace-tiller-certs"

  tls_algorithm_config = "${var.private_key_algorithm == "ECDSA" ? "--tls-private-key-ecdsa-curve ${var.private_key_ecdsa_curve}" : "--tls-private-key-rsa-bits ${var.private_key_rsa_bits}"}"

  kubergrunt_auth_params = <<-EOF
   ${
     var.kubectl_server_endpoint != ""
     ? "--kubectl-server-endpoint \"$KUBECTL_SERVER_ENDPOINT\" --kubectl-certificate-authority \"$KUBECTL_CA_DATA\" --kubectl-token \"$KUBECTL_TOKEN\""
     : ""
   } ${local.esc_newl}
   ${
     var.kubectl_config_path != ""
     ? "--kubeconfig ${var.kubectl_config_path}"
     : ""
   } ${local.esc_newl}
   ${
     var.kubectl_config_context_name != ""
     ? "--kubectl-context-name ${var.kubectl_config_context_name}"
     : ""
   } ${local.esc_newl}
  EOF

  kubectl_auth_params = <<-EOF
    ${
      var.kubectl_server_endpoint != ""
      ? "--server \"$KUBECTL_SERVER_ENDPOINT\" --certificate-authority \"${path.module}/kubernetes_server_ca.pem\" --token \"$KUBECTL_TOKEN\""
      : ""
    } ${local.esc_newl}
   ${
     var.kubectl_config_path != ""
     ? "--kubeconfig ${var.kubectl_config_path}"
     : ""
   } ${local.esc_newl}
   ${
     var.kubectl_config_context_name != ""
     ? "--context ${var.kubectl_config_context_name}"
     : ""
   } ${local.esc_newl}
  EOF

  esc_newl = "${module.os.name == "Windows" ? "`" : "\\"}"
}

# Identify the operating system platform we are executing on
module "os" {
  source = "git::git@github.com:gruntwork-io/package-terraform-utilities.git//modules/operating-system?ref=v0.0.8"
}
