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

  depends_on = ["null_resource.dependency_getter"]
}

# ---------------------------------------------------------------------------------------------------------------------
# BIND THE PROVIDED ROLES TO THE SERVICE ACCOUNT
# ---------------------------------------------------------------------------------------------------------------------

resource "kubernetes_role_binding" "service_account_role_binding" {
  count = "${var.num_rbac_roles}"

  metadata {
    name        = "${var.name}-${lookup(var.rbac_roles[count.index], "name")}-role-binding"
    namespace   = "${lookup(var.rbac_roles[count.index], "namespace")}"
    labels      = "${var.labels}"
    annotations = "${var.annotations}"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "${lookup(var.rbac_roles[count.index], "name")}"
  }

  subject {
    api_group = ""
    kind      = "ServiceAccount"
    name      = "${kubernetes_service_account.service_account.metadata.0.name}"
    namespace = "${var.namespace}"
  }

  depends_on = ["null_resource.dependency_getter"]
}
