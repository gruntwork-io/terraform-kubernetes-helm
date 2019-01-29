# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CONFIGURE OUR KUBERNETES CONNECTIONS
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

provider "kubernetes" {
  config_context = "${var.kubectl_config_context_name}"
  config_path    = "${var.kubectl_config_path}"
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE THE HELM SERVER
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

module "helm_server" {
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
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE THE NAMESPACE WITH RBAC ROLES AND SERVICE ACCOUNT
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

module "tiller_namespace" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-kubernetes-helm.git//modules/k8s-namespace?ref=v0.1.0"
  source = "../../modules/k8s-namespace"

  kubectl_config_context_name = "${var.kubectl_config_context_name}"
  kubectl_config_path         = "${var.kubectl_config_path}"
  name                        = "${var.tiller_namespace}"
}

module "resource_namespace" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-kubernetes-helm.git//modules/k8s-namespace?ref=v0.1.0"
  source = "../../modules/k8s-namespace"

  kubectl_config_context_name = "${var.kubectl_config_context_name}"
  kubectl_config_path         = "${var.kubectl_config_path}"
  name                        = "${var.resource_namespace}"
}

module "tiller_service_account" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-kubernetes-helm.git//modules/k8s-service-account?ref=v0.1.0"
  source = "../../modules/k8s-service-account"

  kubectl_config_context_name = "${var.kubectl_config_context_name}"
  kubectl_config_path         = "${var.kubectl_config_path}"
  name                        = "${var.service_account_name}"
  namespace                   = "${module.tiller_namespace.name}"
  rbac_roles                  = ["${module.tiller_namespace.rbac_access_all_role}", "${module.resource_namespace.rbac_access_all_role}"]

  labels = {
    app = "tiller"
  }
}
