provider "kubernetes" {
  config_context = "${var.kubectl_config_context_name}"
}

module "helm_server" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/package-k8s.git//modules/k8s-helm-server?ref=v0.1.0"
  source = "../../modules/k8s-helm-server"

  kubectl_context = "${var.kubectl_config_context_name}"
  namespace       = "${module.helm_namespace.name}"
  service_account = "${var.service_account_name}"
  tls_subject     = "${var.tls_subject}"
}

module "helm_namespace" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/package-k8s.git//modules/k8s-namespace?ref=v0.1.0"
  source = "../../modules/k8s-namespace"

  kubectl_context = "${var.kubectl_config_context_name}"
  name            = "${var.namespace}"
}

module "helm_service_account" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/package-k8s.git//modules/k8s-service-account?ref=v0.1.0"
  source = "../../modules/k8s-service-account"

  kubectl_context = "${var.kubectl_config_context_name}"
  name            = "${var.service_account_name}"
  namespace       = "${module.helm_namespace.name}"
  rbac_roles      = ["${module.helm_namespace.rbac_access_all_role}"]

  labels = {
    app = "tiller"
  }
}
