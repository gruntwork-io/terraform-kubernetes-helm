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
# ---------------------------------------------------------------------------------------------------------------------

resource "kubernetes_role_binding" "service_account_role_binding" {
  count = "${var.num_rbac_roles}"

  metadata {
    name        = "${var.name}-${element(var.rbac_roles, count.index)}-role-binding"
    namespace   = "${var.namespace}"
    labels      = "${var.labels}"
    annotations = "${var.annotations}"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "${element(var.rbac_roles, count.index)}"
  }

  subject {
    api_group = ""
    kind      = "ServiceAccount"
    name      = "${kubernetes_service_account.service_account.metadata.0.name}"
    namespace = "${var.namespace}"
  }
}
