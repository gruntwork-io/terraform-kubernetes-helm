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
  required_version = ">= 0.12"
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
    instance = join(",", var.dependencies)
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE DEPLOYMENT RESOURCE
# ---------------------------------------------------------------------------------------------------------------------

# Adapted from Tiller installer in helm client. See:
# https://github.com/helm/helm/blob/master/cmd/helm/installer/install.go#L200
resource "kubernetes_deployment" "tiller" {
  depends_on = [
    null_resource.dependency_getter,
    null_resource.tls_secret_generated,
    null_resource.tiller_tls_certs,
  ]

  metadata {
    namespace   = var.namespace
    name        = var.deployment_name
    annotations = var.deployment_annotations

    # The labels app=helm and name=tiller need to be added for helm client to work.
    labels = merge(
      {
        "app"  = "helm"
        "name" = "tiller"
      },
      var.deployment_labels,
    )
  }

  spec {
    replicas = var.deployment_replicas

    # Only manage the Tiller pods deployed by this deployment
    selector {
      match_labels = {
        app        = "helm"
        name       = "tiller"
        deployment = var.deployment_name
      }
    }

    template {
      metadata {
        labels = {
          app        = "helm"
          name       = "tiller"
          deployment = var.deployment_name
        }
      }

      spec {
        service_account_name = var.tiller_service_account_name

        container {
          name              = "tiller"
          image             = "${var.tiller_image}:${var.tiller_image_version}"
          image_pull_policy = var.tiller_image_pull_policy
          command           = ["/tiller"]

          args = concat([
            "--storage=secret",
            "--tls-key=${local.tls_certs_mount_path}/${var.tiller_tls_key_file_name}",
            "--tls-cert=${local.tls_certs_mount_path}/${var.tiller_tls_cert_file_name}",
            "--tls-ca-cert=${local.tls_certs_mount_path}/${var.tiller_tls_cacert_file_name}",
          ], local.tiller_listen_localhost_arg)

          env {
            name  = "TILLER_NAMESPACE"
            value = var.namespace
          }

          env {
            name  = "TILLER_HISTORY_MAX"
            value = var.tiller_history_max
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
            mount_path = local.service_account_token_mount_path
            name       = var.tiller_service_account_token_secret_name
            read_only  = true
          }

          # Mount the TLS certs into the location Tiller expects
          volume_mount {
            mount_path = local.tls_certs_mount_path
            name       = local.tls_secret_volume_name
            read_only  = true
          }
          # end container
        }

        # We have to mount the service account token so that Tiller can access the Kubernetes API as the attached
        # ServiceAccount.
        volume {
          name = var.tiller_service_account_token_secret_name

          secret {
            secret_name = var.tiller_service_account_token_secret_name
          }
        }

        # Mount the volume for the TLS secrets
        volume {
          name = local.tls_secret_volume_name

          secret {
            secret_name = local.generated_tls_secret_name
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
  depends_on = [null_resource.dependency_getter]

  metadata {
    namespace   = var.namespace
    name        = var.service_name
    annotations = var.service_annotations

    # The labels app=helm and name=tiller need to be added for helm client to work.
    labels = merge(
      {
        "app"  = "helm"
        "name" = "tiller"
      },
      var.service_labels,
    )
  }

  spec {
    type = "ClusterIP"

    port {
      name        = "tiller"
      port        = 44134
      target_port = "tiller"
    }

    selector = {
      app        = "helm"
      name       = "tiller"
      deployment = var.deployment_name
    }
  }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# [KUBERGRUNT] GENERATE TLS CERTIFICATES FOR USE WITH TILLER
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Generate CA TLS certs
resource "null_resource" "tiller_tls_ca_certs" {
  count      = var.tiller_tls_gen_method == "kubergrunt" ? 1 : 0
  depends_on = [null_resource.dependency_getter]

  provisioner "local-exec" {
    interpreter = local.is_windows ? ["PowerShell", "-Command"] : ["bash", "-c"]

    command = <<-EOF
      ${lookup(module.require_executables.executables, "kubergrunt", "")} tls gen ${local.esc_newl}
        ${local.kubergrunt_auth_params} ${local.esc_newl}
        --ca ${local.esc_newl}
        --namespace ${var.tiller_tls_ca_cert_secret_namespace} ${local.esc_newl}
        --secret-name ${local.tiller_tls_ca_certs_secret_name} ${local.esc_newl}
        --secret-label gruntwork.io/tiller-namespace=${var.namespace} ${local.esc_newl}
        --secret-label gruntwork.io/tiller-credentials=true ${local.esc_newl}
        --secret-label gruntwork.io/tiller-credentials-type=ca ${local.esc_newl}
        --tls-subject-json '${local.tiller_tls_ca_certs_subject_json_as_arg}' ${local.esc_newl}
        --tls-private-key-algorithm ${var.private_key_algorithm} ${local.esc_newl}
        ${local.tls_algorithm_config}
      EOF

    # Use environment variables for Kubernetes credentials to avoid leaking into the logs
    environment = {
      KUBECTL_SERVER_ENDPOINT = var.kubectl_server_endpoint
      KUBECTL_CA_DATA         = var.kubectl_ca_b64_data
      KUBECTL_TOKEN           = var.kubectl_token
    }
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = local.is_windows ? ["PowerShell", "-Command"] : ["bash", "-c"]

    command = <<-EOF
      ${lookup(module.require_executables.executables, "kubergrunt", "")} k8s kubectl ${local.esc_newl}
        ${local.kubergrunt_auth_params} ${local.esc_newl}
        -- delete secret ${local.tiller_tls_ca_certs_secret_name} -n ${var.tiller_tls_ca_cert_secret_namespace}
      EOF

    # Use environment variables for Kubernetes credentials to avoid leaking into the logs
    environment = {
      KUBECTL_SERVER_ENDPOINT = var.kubectl_server_endpoint
      KUBECTL_CA_DATA         = var.kubectl_ca_b64_data
      KUBECTL_TOKEN           = var.kubectl_token
    }
  }
}

# Use generated CA certs to create new certs for server
resource "null_resource" "tiller_tls_certs" {
  count      = var.tiller_tls_gen_method == "kubergrunt" ? 1 : 0
  depends_on = [null_resource.dependency_getter]

  triggers = {
    ca_cert_create_action = element(concat(null_resource.tiller_tls_ca_certs.*.id, [""]), 0)
  }

  provisioner "local-exec" {
    interpreter = local.is_windows ? ["PowerShell", "-Command"] : ["bash", "-c"]

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
        --tls-subject-json '${local.tiller_tls_subject_json_as_arg}' ${local.esc_newl}
        --tls-private-key-algorithm ${var.private_key_algorithm} ${local.esc_newl}
        ${local.tls_algorithm_config}
      EOF

    # Use environment variables for Kubernetes credentials to avoid leaking into the logs
    environment = {
      KUBECTL_SERVER_ENDPOINT = var.kubectl_server_endpoint
      KUBECTL_CA_DATA         = var.kubectl_ca_b64_data
      KUBECTL_TOKEN           = var.kubectl_token
    }
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = local.is_windows ? ["PowerShell", "-Command"] : ["bash", "-c"]

    command = <<-EOF
      ${lookup(module.require_executables.executables, "kubergrunt", "")} k8s kubectl ${local.esc_newl}
        ${local.kubergrunt_auth_params} ${local.esc_newl}
        -- delete secret ${local.tiller_tls_certs_secret_name} -n ${var.namespace}
      EOF

    # Use environment variables for Kubernetes credentials to avoid leaking into the logs
    environment = {
      KUBECTL_SERVER_ENDPOINT = var.kubectl_server_endpoint
      KUBECTL_CA_DATA         = var.kubectl_ca_b64_data
      KUBECTL_TOKEN           = var.kubectl_token
    }
  }
}

module "require_executables" {
  source = "git::https://github.com/gruntwork-io/package-terraform-utilities.git//modules/require-executable?ref=v0.1.0"

  # We have two items in the list here with conditionals, because terraform does not allow list values in conditionals.
  # TODO: revisit with TF 12
  required_executables = [
    var.tiller_tls_gen_method == "kubergrunt" ? "kubergrunt" : "",
    var.tiller_tls_gen_method == "kubergrunt" ? "kubectl" : "",
  ]

  error_message = "The __EXECUTABLE_NAME__ binary is not available in your PATH. Install the binary by following the instructions at https://github.com/gruntwork-io/terraform-kubernetes-helm/blob/master/modules/k8s-tiller/README.md#generating-with-kubergrunt, or update your PATH variable to search where you installed __EXECUTABLE_NAME__."
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# [PROVIDER] GENERATE TLS CERTIFICATES FOR USE WITH TILLER
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

module "tiller_tls_certs" {
  source = "../k8s-tiller-tls-certs"

  ca_tls_subject = local.tiller_tls_ca_certs_subject

  ca_tls_certificate_key_pair_secret_namespace = var.tiller_tls_ca_cert_secret_namespace
  ca_tls_certificate_key_pair_secret_name      = local.tiller_tls_ca_certs_secret_name

  ca_tls_certificate_key_pair_secret_labels = {
    "gruntwork.io/tiller-namespace"        = var.namespace
    "gruntwork.io/tiller-credentials"      = "true"
    "gruntwork.io/tiller-credentials-type" = "ca"
  }

  signed_tls_subject                               = var.tiller_tls_subject
  signed_tls_certificate_key_pair_secret_namespace = var.namespace
  signed_tls_certificate_key_pair_secret_name      = local.tiller_tls_certs_secret_name

  signed_tls_certificate_key_pair_secret_labels = {
    "gruntwork.io/tiller-namespace"        = var.namespace
    "gruntwork.io/tiller-credentials"      = "true"
    "gruntwork.io/tiller-credentials-type" = "server"
  }

  private_key_algorithm   = var.private_key_algorithm
  private_key_ecdsa_curve = var.private_key_ecdsa_curve
  private_key_rsa_bits    = var.private_key_rsa_bits

  create_resources = var.tiller_tls_gen_method == "provider"
  dependencies     = [null_resource.dependency_getter.id]
}

resource "null_resource" "tls_secret_generated" {
  count = var.tiller_tls_gen_method == "provider" ? 1 : 0

  triggers = {
    instance = module.tiller_tls_certs.signed_tls_certificate_key_pair_secret_name
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
  generated_tls_secret_name = var.tiller_tls_gen_method == "none" ? var.tiller_tls_secret_name : local.tiller_tls_certs_secret_name

  # The CA TLS subject is the same as the Tiller server, except we append CA to the common name to differentiate it from
  # the server.
  tiller_tls_ca_certs_subject = merge(
    var.tiller_tls_subject,
    {
      "common_name" = "${var.tiller_tls_subject["common_name"]} CA"
    },
  )
  tiller_tls_ca_certs_subject_json = jsonencode(local.tiller_tls_ca_certs_subject)
  tiller_tls_subject_json          = jsonencode(var.tiller_tls_subject)

  # In Powershell, double quotes must be escaped so before we pass the json to the command, we pass it through a replace
  # call. Additionally, due to the weird quoting rules, we need to make sure there is a space after each colon.
  tiller_tls_ca_certs_subject_json_as_arg = (
    local.is_windows
    ? replace(
      replace(local.tiller_tls_ca_certs_subject_json, "\"", "\\\""),
      ":",
      ": ",
    )
    : local.tiller_tls_ca_certs_subject_json
  )
  tiller_tls_subject_json_as_arg = (
    local.is_windows
    ? replace(
      replace(local.tiller_tls_subject_json, "\"", "\\\""),
      ":",
      ": ",
    )
    : local.tiller_tls_subject_json
  )

  # These Secret names are set based on what is expected by `kubergrunt helm grant`
  tiller_tls_ca_certs_secret_name = "${var.namespace}-namespace-tiller-ca-certs"
  tiller_tls_certs_secret_name    = "${var.namespace}-namespace-tiller-certs"

  tiller_listen_localhost_arg = var.tiller_listen_localhost ? ["--listen=localhost:44134"] : []

  # Derive the CLI args for the TLS algorithm config from the input variables
  tls_algorithm_config = var.private_key_algorithm == "ECDSA" ? "--tls-private-key-ecdsa-curve ${var.private_key_ecdsa_curve}" : "--tls-private-key-rsa-bits ${var.private_key_rsa_bits}"

  # Make sure we expand the ~
  kubectl_config_path = pathexpand(var.kubectl_config_path)

  # Configure the CLI args to pass to kubergrunt to authenticate to the kubernetes cluster based on user input to the
  # module
  kubergrunt_auth_params = <<-EOF
    ${var.kubectl_server_endpoint != "" ? "--kubectl-server-endpoint \"${local.env_prefix}KUBECTL_SERVER_ENDPOINT\" --kubectl-certificate-authority \"${local.env_prefix}KUBECTL_CA_DATA\" --kubectl-token \"${local.env_prefix}KUBECTL_TOKEN\"" : ""} ${local.esc_newl}
    ${var.kubectl_config_path != "" ? "--kubeconfig ${local.kubectl_config_path}" : ""} ${local.esc_newl}
    ${var.kubectl_config_context_name != "" ? "--kubectl-context-name ${var.kubectl_config_context_name}" : ""} ${local.esc_newl}
    EOF

  # The environment variable prefix and newline escape differs between bash and powershell, so we compute that here
  # based on the OS
  is_windows = module.os.name == "Windows"
  env_prefix = local.is_windows ? "$env:" : "$"
  esc_newl   = local.is_windows ? "`" : "\\"
}

# Identify the operating system platform we are executing on
module "os" {
  source = "git::https://github.com/gruntwork-io/package-terraform-utilities.git//modules/operating-system?ref=v0.1.0"
}
