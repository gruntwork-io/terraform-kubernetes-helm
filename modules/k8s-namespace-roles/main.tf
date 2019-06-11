# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE DEFAULT RBAC ROLES FOR A KUBERNETES NAMESPACE
# These templates provision a set of default RBAC roles with permissions scoped to the provided namespace.
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
  count      = var.create_resources ? 1 : 0
  depends_on = [null_resource.dependency_getter]

  metadata {
    name        = "${var.namespace}-access-all"
    namespace   = var.namespace
    labels      = var.labels
    annotations = var.annotations
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
  }
}

resource "kubernetes_role" "rbac_role_access_read_only" {
  count      = var.create_resources ? 1 : 0
  depends_on = [null_resource.dependency_getter]

  metadata {
    name        = "${var.namespace}-access-read-only"
    namespace   = var.namespace
    labels      = var.labels
    annotations = var.annotations
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["get", "list", "watch"]
  }
}

# These RBAC role permissions are based on the official example regarding deploying Tiller in a namespace to manage
# resources in another namespace.
# See https://docs.helm.sh/using_helm/#example-deploy-tiller-in-a-namespace-restricted-to-deploying-resources-in-another-namespace

resource "kubernetes_role" "rbac_tiller_metadata_access" {
  count      = var.create_resources ? 1 : 0
  depends_on = [null_resource.dependency_getter]

  metadata {
    name        = "${var.namespace}-tiller-metadata-access"
    namespace   = var.namespace
    labels      = var.labels
    annotations = var.annotations
  }

  rule {
    api_groups = ["", "extensions", "apps"]
    resources  = ["secrets"]
    verbs      = ["*"]
  }
}

resource "kubernetes_role" "rbac_tiller_resource_access" {
  count      = var.create_resources ? 1 : 0
  depends_on = [null_resource.dependency_getter]

  metadata {
    name        = "${var.namespace}-tiller-resource-access"
    namespace   = var.namespace
    labels      = var.labels
    annotations = var.annotations
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

  # We include policy PodDisruptionBudget which is useful for the helm charts to manage
  rule {
    api_groups = [
      "policy",
    ]

    resources = ["poddisruptionbudgets"]
    verbs     = ["*"]
  }
}
