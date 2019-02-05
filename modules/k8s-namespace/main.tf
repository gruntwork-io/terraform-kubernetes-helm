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
# This defines four default RBAC roles scoped to the namespace:
# - namespace-access-all : Admin level permissions on all resources in the namespace.
# - namespace-access-read-only: Read only permissions on all resources in the namespace.
# - namespace-tiller-metadata-access: Minimal permissions for Tiller to manage its metadata in this namespace (if this
#                                     namespace is where Tiller is deployed).
# - namespace-tiller-resource-access: Minimal permissions for Tiller to manage resources in this namespace as Helm
#                                     charts.
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

  depends_on = ["null_resource.dependency_getter"]
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

  depends_on = ["null_resource.dependency_getter"]
}

# These RBAC role permissions are based on the official example regarding deploying Tiller in a namespace to manage
# resources in another namespace.
# See https://docs.helm.sh/using_helm/#example-deploy-tiller-in-a-namespace-restricted-to-deploying-resources-in-another-namespace

resource "kubernetes_role" "rbac_tiller_metadata_access" {
  metadata {
    name        = "${var.name}-tiller-metadata-access"
    namespace   = "${kubernetes_namespace.namespace.id}"
    labels      = "${var.labels}"
    annotations = "${var.annotations}"
  }

  rule {
    api_groups = ["", "extensions", "apps"]
    resources  = ["secrets"]
    verbs      = ["*"]
  }

  depends_on = ["null_resource.dependency_getter"]
}

resource "kubernetes_role" "rbac_tiller_resource_access" {
  metadata {
    name        = "${var.name}-tiller-resource-access"
    namespace   = "${kubernetes_namespace.namespace.id}"
    labels      = "${var.labels}"
    annotations = "${var.annotations}"
  }

  rule {
    api_groups = [
      "",
      "batch",
      "extensions",
      "apps",
      "rbac.authorization.k8s.io", # We include RBAC here because many helm charts create RBAC roles to minimize pod access.
    ]

    resources = ["*"]
    verbs     = ["*"]
  }

  depends_on = ["null_resource.dependency_getter"]
}
