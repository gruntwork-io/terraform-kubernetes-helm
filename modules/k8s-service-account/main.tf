# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE KUBERNETES SERVICE ACCOUNT AND BIND THE ROLES
# These templates provision a new ServiceAccount in the Kubernetes cluster, as well as a RoleBinding object that will
# bind the provided roles to the ServiceAccount.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ---------------------------------------------------------------------------------------------------------------------
# SET TERRAFORM REQUIREMENTS FOR RUNNING THIS MODULE
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = "~> 0.9"
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE SERVICE ACCOUNT
# ---------------------------------------------------------------------------------------------------------------------

resource "kubernetes_service_account" "service_account" {
  metadata {
    name        = "${var.name}"
    namespace   = "${var.namespace}"
    labels      = "${var.labels}"
    annotations = "${var.annotations}"
  }

  image_pull_secret               = "${var.secrets_for_pulling_images}"
  secret                          = "${var.secrets_for_pods}"
  automount_service_account_token = "${var.automount_service_account_token}"
}

# ---------------------------------------------------------------------------------------------------------------------
# BIND THE PROVIDED ROLES TO THE SERVICE ACCOUNT
# NOTE: replace below with resources from the Terraform Kubernetes provider when they become available.
# - Open PR: https://github.com/terraform-providers/terraform-provider-kubernetes/pull/235
# ---------------------------------------------------------------------------------------------------------------------

locals {
  kubectl_config_options = "${var.kubectl_config_context_name != "" ? "--context ${var.kubectl_config_context_name}" : ""} ${var.kubectl_config_path != "" ? "--kubeconfig ${var.kubectl_config_path}" : ""}"
}

resource "null_resource" "rbac_role_binding" {
  provisioner "local-exec" {
    command = "echo '${data.template_file.rbac_role_binding_list.rendered}' | kubectl auth reconcile ${local.kubectl_config_options} -f -"
  }

  provisioner "local-exec" {
    command = "echo '${data.template_file.rbac_role_binding_list.rendered}' | kubectl delete ${local.kubectl_config_options} -f -"
    when    = "destroy"
  }
}
