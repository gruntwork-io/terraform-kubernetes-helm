# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DEPLOY TILLER INTO A NEW NAMESPACE
# These templates show an example of how to deploy Tiller following security best practices. This entails:
# - Creating a Namespace and ServiceAccount for Tiller
# - Creating a separate Namespace for the resources to go into
# - Using kubergrunt to deploy Tiller with TLS management
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

terraform {
  required_version = ">= 0.12"
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CONFIGURE OUR KUBERNETES CONNECTIONS
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

provider "kubernetes" {
  config_context = var.kubectl_config_context_name
  config_path    = var.kubectl_config_path
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE THE NAMESPACE WITH RBAC ROLES AND SERVICE ACCOUNT
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

module "tiller_namespace" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::https://github.com/gruntwork-io/terraform-kubernetes-helm.git//modules/k8s-namespace?ref=v0.3.0"
  source = "../../modules/k8s-namespace"

  name = var.tiller_namespace
}

module "resource_namespace" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::https://github.com/gruntwork-io/terraform-kubernetes-helm.git//modules/k8s-namespace?ref=v0.3.0"
  source = "../../modules/k8s-namespace"

  name = var.resource_namespace
}

module "tiller_service_account" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::https://github.com/gruntwork-io/terraform-kubernetes-helm.git//modules/k8s-service-account?ref=v0.3.0"
  source = "../../modules/k8s-service-account"

  name           = var.service_account_name
  namespace      = module.tiller_namespace.name
  num_rbac_roles = 2

  rbac_roles = [
    {
      name      = module.tiller_namespace.rbac_tiller_metadata_access_role
      namespace = module.tiller_namespace.name
    },
    {
      name      = module.resource_namespace.rbac_tiller_resource_access_role
      namespace = module.resource_namespace.name
    },
  ]

  labels = {
    app = "tiller"
  }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DEPLOY TILLER
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

module "tiller" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::https://github.com/gruntwork-io/terraform-kubernetes-helm.git//modules/k8s-tiller?ref=v0.3.0"
  source = "../../modules/k8s-tiller"

  tiller_service_account_name              = module.tiller_service_account.name
  tiller_service_account_token_secret_name = module.tiller_service_account.token_secret_name
  namespace                                = module.tiller_namespace.name
  tiller_image_version                     = var.tiller_version

  tiller_tls_gen_method   = "kubergrunt"
  tiller_tls_subject      = var.tls_subject
  private_key_algorithm   = var.private_key_algorithm
  private_key_ecdsa_curve = var.private_key_ecdsa_curve
  private_key_rsa_bits    = var.private_key_rsa_bits

  kubectl_config_context_name = var.kubectl_config_context_name
  kubectl_config_path         = var.kubectl_config_path
}

# We use kubergrunt to wait for Tiller to be deployed. Any resources that depend on this can assume Tiller is
# successfully deployed and up at that point.
resource "null_resource" "wait_for_tiller" {
  provisioner "local-exec" {
    interpreter = local.is_windows ? ["PowerShell", "-Command"] : ["bash", "-c"]

    command = <<-EOF
      ${module.require_executables.executables["kubergrunt"]} helm wait-for-tiller ${local.esc_newl}
        --tiller-namespace ${module.tiller_namespace.name} ${local.esc_newl}
        --tiller-deployment-name ${module.tiller.deployment_name} ${local.esc_newl}
        --expected-tiller-version ${var.tiller_version}
      EOF
  }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CONFIGURE OPERATOR HELM CLIENT
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

resource "null_resource" "grant_helm_access" {
  count      = var.configure_helm ? 1 : 0
  depends_on = [null_resource.wait_for_tiller]

  provisioner "local-exec" {
    interpreter = local.is_windows ? ["PowerShell", "-Command"] : ["bash", "-c"]

    command = <<-EOF
      ${module.require_executables.executables["kubergrunt"]} helm grant ${local.esc_newl}
        --tiller-namespace ${module.tiller_namespace.name} ${local.esc_newl}
        ${local.kubectl_config_options} ${local.esc_newl}
        --tls-subject-json '${jsonencode(var.client_tls_subject)}' ${local.esc_newl}
        ${local.configure_args}

      ${module.require_executables.executables["kubergrunt"]} helm configure ${local.esc_newl}
        --helm-home ${local.helm_home_with_default} ${local.esc_newl}
        --tiller-namespace ${module.tiller_namespace.name} ${local.esc_newl}
        --resource-namespace ${module.resource_namespace.name} ${local.esc_newl}
        ${local.kubectl_config_options} ${local.esc_newl}
        ${local.configure_args}
      EOF
  }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# COMPUTATIONS
# These locals compute various useful information used throughout this Terraform module.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

locals {
  kubectl_config_options = "${var.kubectl_config_context_name != "" ? "--kubectl-context-name ${var.kubectl_config_context_name}" : ""} ${var.kubectl_config_path != "" ? "--kubeconfig ${var.kubectl_config_path}" : ""}"

  helm_home_with_default = var.helm_home == "" ? pathexpand("~/.helm") : var.helm_home

  configure_args = var.helm_client_rbac_user != "" ? "--rbac-user ${var.helm_client_rbac_user}" : var.helm_client_rbac_group != "" ? "--rbac-group ${var.helm_client_rbac_group}" : var.helm_client_rbac_service_account != "" ? "--rbac-service-account ${var.helm_client_rbac_service_account}" : ""

  is_windows = module.os.name == "Windows"
  esc_newl   = local.is_windows ? "`" : "\\"
}

module "os" {
  source = "git::https://github.com/gruntwork-io/package-terraform-utilities.git//modules/operating-system?ref=v0.1.0"
}

module "require_executables" {
  source = "git::https://github.com/gruntwork-io/package-terraform-utilities.git//modules/require-executable?ref=v0.1.0"

  required_executables = ["kubergrunt"]
  error_message        = "The __EXECUTABLE_NAME__ binary is not available in your PATH. Install the binary by following the instructions at https://github.com/gruntwork-io/terraform-kubernetes-helm/blob/master/examples/k8s-tiller-kubergrunt-minikube/README.md#installing-necessary-tools, or update your PATH variable to search where you installed __EXECUTABLE_NAME__."
}
