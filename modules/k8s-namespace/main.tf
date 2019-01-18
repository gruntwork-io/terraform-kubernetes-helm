# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE KUBERNETES NAMESPACE WITH DEFAULT RBAC ROLES
# These templates provision a new namespace in the Kubernetes cluster, as well as a set of default RBAC roles with
# permissions scoped to the namespace.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ---------------------------------------------------------------------------------------------------------------------
# SET TERRAFORM REQUIREMENTS FOR RUNNING THIS MODULE
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = "~> 0.9"
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE NAMESPACE
# ---------------------------------------------------------------------------------------------------------------------

resource "kubernetes_namespace" "namespace" {
  metadata {
    name        = "${var.name}"
    labels      = "${var.labels}"
    annotations = "${var.annotations}"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE DEFAULT RBAC ROLES
# This defines two default RBAC roles scoped to the namespace:
# - namespace-access-all : Admin level permissions on all resources in the namespace.
# - namespace-access-read-only: Read only permissions on all resources in the namespace.
# ---------------------------------------------------------------------------------------------------------------------

resource "kubernetes_role" "rbac_role_access_all" {
  metadata {
    name        = "${var.name}-access-all"
    namespace   = "${var.name}"
    labels      = "${var.labels}"
    annotations = "${var.annotations}"
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
  }
}

resource "kubernetes_role" "rbac_role_access_read_only" {
  metadata {
    name      = "${var.name}-access-read-only"
    namespace = "${var.name}"
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["get", "list", "watch"]
  }
}
