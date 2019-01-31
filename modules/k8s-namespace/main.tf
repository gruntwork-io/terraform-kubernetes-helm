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
# SET MODULE DEPENDENCY RESOURCE
# This works around a terraform limitation where we can not specify module dependencies natively.
# See https://github.com/hashicorp/terraform/issues/1178 for more discussion.
# ---------------------------------------------------------------------------------------------------------------------

resource "null_resource" "dependency_getter" {
  provisioner "local-exec" {
    command = "echo ${length(var.dependencies)}"
  }
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

  depends_on = ["null_resource.dependency_getter"]
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
    namespace   = "${kubernetes_namespace.namespace.id}"
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
    name        = "${var.name}-access-read-only"
    namespace   = "${kubernetes_namespace.namespace.id}"
    labels      = "${var.labels}"
    annotations = "${var.annotations}"
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["get", "list", "watch"]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# SET MODULE CHILD DEPENDENCY RESOURCE
# This works around a terraform limitation where we can not specify module dependencies natively.
# See https://github.com/hashicorp/terraform/issues/1178 for more discussion.
# ---------------------------------------------------------------------------------------------------------------------

# List resource(s) that will be constructed last within the module, so that we can create an output that can be used to
# chain dependencies.
resource "null_resource" "dependency_setter" {
  depends_on = ["kubernetes_role.rbac_role_access_read_only", "kubernetes_role.rbac_role_access_all"]
}
