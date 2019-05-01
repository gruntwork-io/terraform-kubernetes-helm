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
# By resolving and computing the dependencies list, we are able to make all the resources in this module depend on the
# resources backing the values in the dependencies list.
# ---------------------------------------------------------------------------------------------------------------------

resource "null_resource" "wait_for" {
  triggers = {
    instance = "${join(" ", var.wait_for)}"
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

  depends_on = ["null_resource.wait_for"]
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE DEFAULT RBAC ROLES
# This uses `k8s-namespace-roles` to define a set of commonly used RBAC roles.
# ---------------------------------------------------------------------------------------------------------------------

module "namespace_roles" {
  source = "../k8s-namespace-roles"

  namespace   = "${kubernetes_namespace.namespace.id}"
  labels      = "${var.labels}"
  annotations = "${var.annotations}"
  wait_for    = ["${var.wait_for}"]
}
