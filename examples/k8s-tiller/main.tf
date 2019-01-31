# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CONFIGURE OUR KUBERNETES CONNECTIONS
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

provider "kubernetes" {
  config_context = "${var.kubectl_config_context_name}"
  config_path    = "${var.kubectl_config_path}"
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DEPLOY TILLER
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

module "tiller" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-kubernetes-helm.git//modules/k8s-tiller?ref=v0.1.0"
  source = "../../modules/k8s-tiller"

  kubectl_config_context_name = "${var.kubectl_config_context_name}"
  kubectl_config_path         = "${var.kubectl_config_path}"
  tiller_namespace            = "${module.tiller_namespace.name}"
  resource_namespace          = "${module.resource_namespace.name}"
  service_account             = "${module.tiller_service_account.name}"
  tls_subject                 = "${var.tls_subject}"

  grant_access_to_rbac_users            = ["${var.grant_access_to_rbac_users}"]
  grant_access_to_rbac_groups           = ["${var.grant_access_to_rbac_groups}"]
  grant_access_to_rbac_service_accounts = ["${var.grant_access_to_rbac_service_accounts}"]
  helm_client_rbac_user                 = "${var.helm_client_rbac_user}"
  helm_client_rbac_group                = "${var.helm_client_rbac_group}"
  helm_client_rbac_service_account      = "${var.helm_client_rbac_service_account}"

  # We force remove Tiller here for testing purposes when you run destroy, but in production, you may want more conservative options.
  force_undeploy    = true
  undeploy_releases = true

  # We specify these as dependencies for this module, because we can't destroy Tiller if the roles are removed (and thus
  # we lose access!)
  dependencies = [
    "${module.tiller_namespace.rbac_access_all_role}",
    "${module.resource_namespace.rbac_access_all_role}",
    "${module.tiller_service_account.depended_on}",
  ]
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE THE NAMESPACE WITH RBAC ROLES AND SERVICE ACCOUNT
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

module "tiller_namespace" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-kubernetes-helm.git//modules/k8s-namespace?ref=v0.1.0"
  source = "../../modules/k8s-namespace"

  name = "${var.tiller_namespace}"
}

module "resource_namespace" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-kubernetes-helm.git//modules/k8s-namespace?ref=v0.1.0"
  source = "../../modules/k8s-namespace"

  name = "${var.resource_namespace}"
}

module "tiller_service_account" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-kubernetes-helm.git//modules/k8s-service-account?ref=v0.1.0"
  source = "../../modules/k8s-service-account"

  name                 = "${var.service_account_name}"
  namespace            = "${module.tiller_namespace.name}"
  num_rbac_roles       = 2
  rbac_roles           = ["${module.tiller_namespace.rbac_access_all_role}", "${module.resource_namespace.rbac_access_all_role}"]
  rbac_role_namespaces = ["${module.tiller_namespace.name}", "${module.resource_namespace.name}"]

  labels = {
    app = "tiller"
  }
}
