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
# NOTE: replace below with resources from the Terraform Kubernetes provider when they become available.
# - Open PR: https://github.com/terraform-providers/terraform-provider-kubernetes/pull/235
# ---------------------------------------------------------------------------------------------------------------------

locals {
  kubectl_config_options = "${var.kubectl_config_context_name != "" ? "--context ${var.kubectl_config_context_name}" : ""} ${var.kubectl_config_path != "" ? "--kubeconfig ${var.kubectl_config_path}" : ""}"
}

resource "null_resource" "rbac_role_access_all" {
  provisioner "local-exec" {
    command = "echo '${data.template_file.rbac_role_access_all.rendered}' | kubectl auth reconcile ${local.kubectl_config_options} -f -"
  }

  provisioner "local-exec" {
    command = "echo '${data.template_file.rbac_role_access_all.rendered}' | kubectl delete ${local.kubectl_config_options} -f -"
    when    = "destroy"
  }

  depends_on = ["kubernetes_namespace.namespace"]
}

resource "null_resource" "rbac_role_access_read_only" {
  provisioner "local-exec" {
    command = "echo '${data.template_file.rbac_role_access_read_only.rendered}' | kubectl auth reconcile ${local.kubectl_config_options} -f -"
  }

  provisioner "local-exec" {
    command = "echo '${data.template_file.rbac_role_access_read_only.rendered}' | kubectl delete ${local.kubectl_config_options} -f -"
    when    = "destroy"
  }

  depends_on = ["kubernetes_namespace.namespace"]
}
