# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE A NAMESPACE WITH DEFAULT RBAC ROLES AND SERVICE ACCOUNTS BOUND TO THE ROLES
# These templates show an example of how to create a Kubernetes namespace with a set of default RBAC roles, and
# ServiceAccounts that are bound to each default role.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CONFIGURE OUR KUBERNETES CONNECTIONS
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

provider "kubernetes" {
  config_context = "${var.kubectl_config_context_name}"
  config_path    = "${var.kubectl_config_path}"
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE THE NAMESPACE WITH RBAC ROLES
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

module "namespace" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/package-k8s.git//modules/k8s-namespace?ref=v0.1.0"
  source = "../../modules/k8s-namespace"

  kubectl_config_context_name = "${var.kubectl_config_context_name}"
  kubectl_config_path         = "${var.kubectl_config_path}"
  name                        = "${var.name}"
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE THE SERVICE ACCOUNTS
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

module "service_account_access_all" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/package-k8s.git//modules/k8s-service-account?ref=v0.1.0"
  source = "../../modules/k8s-service-account"

  kubectl_config_context_name = "${var.kubectl_config_context_name}"
  kubectl_config_path         = "${var.kubectl_config_path}"
  name                        = "${var.name}-admin"
  namespace                   = "${module.namespace.name}"
  rbac_roles                  = ["${module.namespace.rbac_access_all_role}"]

  # How to tag the service account with a label
  labels = {
    role = "admin"
  }
}

module "service_account_access_read_only" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/package-k8s.git//modules/k8s-service-account?ref=v0.1.0"
  source = "../../modules/k8s-service-account"

  kubectl_config_context_name = "${var.kubectl_config_context_name}"
  kubectl_config_path         = "${var.kubectl_config_path}"
  name                        = "${var.name}-read-only"
  namespace                   = "${module.namespace.name}"
  rbac_roles                  = ["${module.namespace.rbac_access_read_only_role}"]

  # How to tag the service account with a label
  labels = {
    role = "monitor"
  }
}
