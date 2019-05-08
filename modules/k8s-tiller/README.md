# K8S Tiller (Helm Server) Module

<!-- NOTE: We use absolute linking here instead of relative linking, because the terraform registry does not support
           relative linking correctly.
-->

This Terraform Module can be used to declaratively deploy and manage multiple Tiller (the server component of Helm)
deployments in a single Kubernetes cluster.
Unlike the defaults installed by the helm client, the deployed Tiller instances:

- Use Kubernetes Secrets instead of ConfigMaps for storing release information.
- Enable TLS verification and authentication.
- Only listens on localhost within the container.

Note: Please be advised that there are plans by the Helm community to deprecate and remove Tiller starting Helm v3. This
repository will be updated with migration instructions to help smooth out the upgrade when Helm v3 lands.


## How do you use this module?

* See the [root README](https://github.com/gruntwork-io/terraform-kubernetes-helm/blob/master/README.md) for
  instructions on using Terraform modules.
* This module uses [the `kubernetes` provider](https://www.terraform.io/docs/providers/kubernetes/index.html).
* See [the example at the root of the repo](https://github.com/gruntwork-io/terraform-kubernetes-helm) for example
  usage.
* See [variables.tf](https://github.com/gruntwork-io/terraform-kubernetes-helm/blob/master/modules/k8s-tiller/variables.tf)
  for all the variables you can set on this module.
* See [outputs.tf](https://github.com/gruntwork-io/terraform-kubernetes-helm/blob/master/modules/k8s-tiller/outputs.tf)
  for all the variables that are outputed by this module.


## What is Tiller?

Tiller is a component of Helm that runs inside the Kubernetes cluster. Tiller is what provides the functionality to
apply the Kubernetes resource descriptions to the Kubernetes cluster. When you install a release, the helm client
essentially packages up the values and charts as a release, which is submitted to Tiller. Tiller will then generate
Kubernetes YAML files from the packaged release, and then apply the generated Kubernetes YAML file from the charts on
the cluster.

You can read more about Helm, Tiller, and their security model in our [Helm
guide](https://github.com/gruntwork-io/kubergrunt/blob/master/HELM_GUIDE.md).

This module ensures all the security features provided by Helm are employed by:

- Forcing a named `ServiceAccount` and avoiding defaults.
- Enabling TLS verification features


### What ServiceAccount should I use for Tiller?

This module requires a `ServiceAccount` to use for Tiller, specified by the `tiller_service_account_name` and
`tiller_service_account_token_secret_name` input variables. Tiller relies on `ServiceAccounts` and the associated RBAC
roles to properly restrict what Helm Charts can do. The RBAC system in Kubernetes allows the operator to define fine
grained permissions on what an individual or system can do in the cluster. By using RBAC, you can restrict Tiller
installs to only manage resources in particular namespaces, or even restrict what resources Tiller can manage.

The specific roles to use for Tiller depends on your infrastructure needs. At a minimum, Tiller needs enough permissions
to manage its own metadata, and permissions to deploy resources in the target Namespace. We provide minimal permission
sets that you can use in the [k8s-namespace-roles
module](https://github.com/gruntwork-io/terraform-kubernetes-helm/tree/master/modules/k8s-namespace-roles). You can
associate the `rbac_tiller_metadata_access_role` and `rbac_tiller_resource_access_role` roles created by the module to
the Tiller `ServiceAccount` to grant those permissions. For example, the following terraform code will create these
roles in the `kube-system` `Namespace` and attach it to a new `ServiceAccount` that you can then use in this module:

```hcl
module "namespace_roles" {
  source = "git::https://github.com/gruntwork-io/terraform-kubernetes-helm.git//modules/k8s-namespace-roles?ref=v0.3.0"

  namespace    = "kube-system"
}

module "tiller_service_account" {
  source = "git::https://github.com/gruntwork-io/terraform-kubernetes-helm.git//modules/k8s-service-account?ref=v0.3.0"

  name           = "tiller"
  namespace      = "kube-system"
  num_rbac_roles = 2

  rbac_roles = [
    {
      name      = "${module.namespace_roles.rbac_tiller_metadata_access_role}"
      namespace = "kube-system"
    },
    {
      name      = "${module.namespace_roles.rbac_tiller_resource_access_role}"
      namespace = "kube-system"
    },
  ]
}
```

This will create the default roles in the `kube-system` `Namespace`. Then, it will create a new `ServiceAccount` names
`tiller` in the `kube-system` `Namespace`, bound to the metadata access role and resource access role of the
`kube-system` `Namespace`. This allows the `tiller` `ServiceAccount` to manage it's state in Kubernetes `Secrets` in the
`kube-system` `Namespace`, and deploy resources in there.

### TLS authentication and verification

This module installs Tiller with TLS verification turned on. If you are unfamiliar with TLS/SSL, we recommend reading
[this background](https://github.com/hashicorp/terraform-aws-vault/tree/master/modules/private-tls-cert#background)
document describing how it works before continuing.

With this feature, Tiller will validate client side TLS certificates provided as part of the API call to ensure the
client has access. Likewise, the client will also validate the TLS certificates provided by Tiller. In this way, both
the client and the server can trust each other as authorized entities.

To achieve this, we will need to generate a Certificate Authority (CA) that can be used to issue and validate
certificates. This CA will be shared between the server and the client to validate each others' certificates.

Then, using the generated CA, we will issue at least two sets of signed certificates:

- A certificate for Tiller that identifies it.
- A certificate for the Helm client that identifies it.

We recommend that you issue a certificate for each unique helm client (and therefore each user of helm). This makes it
easier to manage access for team changes (e.g when someone leaves the team), as well as compliance requirements (e.g
access logs that uniquely identifies individuals).

Finally, both Tiller and the Helm client need to be setup to utilize the issued certificates.

To summarize, assuming a single client, in this model we have three sets of TLS key pairs in play:

- Key pair for the CA to issue new certificate key pairs.
- Key pair to identify Tiller.
- Key pair to identify the client.

You can use `kubergrunt` to manage TLS certificates optimized for use with Tiller. `kubergrunt` provides various
primitives that can be used for generating and managing TLS certificates using Kubernetes `Secrets`. This allows you to
manage access to Helm using the RBAC system of Kubernetes. See the [k8s-tiller-minikube
example](https://github.com/gruntwork-io/terraform-kubernetes-helm/tree/master/examples/k8s-tiller-minikube) for an
example of how to use `kubergrunt` to generate TLS certs for use with
this module.
