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
  depends_on = ["null_resource.dependency_getter"]

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
            secret_name = "${var.tiller_tls_secret_name}"
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

# ---------------------------------------------------------------------------------------------------------------------
# GLOBAL CONSTANTS
# Avoids the usage of magic strings.
# ---------------------------------------------------------------------------------------------------------------------

locals {
  service_account_token_mount_path = "/var/run/secrets/kubernetes.io/serviceaccount"
  tls_certs_mount_path             = "/etc/certs"
  tls_secret_volume_name           = "tiller-certs"
}
