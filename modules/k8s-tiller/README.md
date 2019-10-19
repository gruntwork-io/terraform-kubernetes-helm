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

This module supports three ways to setup the CA and server side TLS certificates for Tiller:

- [Directly passing it in](#directly-passing-in-tls-certs)
- [Generating with `tls` provider](#generating-with-tls-provider)
- [Generating with `kubergrunt`](#generating-with-kubergrunt)

Summary of differences:

<!-- This table is generated using https://www.tablesgenerator.com/markdown_tables -->

| **Method** | **Amount of Control** | **Terraform Features** | **Secrets in Terraform State**            | **External Dependencies**                    |
|------------|-----------------------|------------------------|-------------------------------------------|----------------------------------------------|
| Direct     | Full control          | N/A                    | Only references                           | Yes (TLS certs must be generated externally) |
| Provider   | Limited control       | Full support           | All Secrets are stored in Terraform State | No                                           |
| Kubergrunt | Limited control       | Limited support        | Only references                           | Yes (kubergrunt binary)                      |


#### Directly passing in TLS certs

This method of configuring the TLS certs requires that the TLS certs have already been generated. To use this method,
set `tiller_tls_gen_method` to `"none"`.

Tiller expects to mount the TLS keys from a `Secret` resource. To directly pass in to Tiller, you must first upload the
TLS certificate key pair with the CA public certificate into a `Secret` resource in the `Namespace` where you intend on
deploying Tiller. Then, you can pass in the name of the `Secret` as the `tiller_tls_secret_name` variable to this module
to deploy Tiller with that `Secret` mounted. You can configure what keys to read the certificate key pairs from using
the `tiller_tls_key_file_name`, `tiller_tls_cert_file_name`, and `tiller_tls_cacert_file_name` variables for the private
key, public certificate, and CA public certificate files respectively.


#### Generating with `tls` provider

**WARNING: The private keys generated using this method will be stored unencrypted in your Terraform state file. If you
are sensitive to storing secrets in your Terraform state file, consider using `kubergrunt` to generate and manage your
TLS certificate. See [Generating with kubergrunt](#generating-with-kubergrunt) for more details.**

This method of configuring the TLS certs utilizes the [k8s-tiller-tls-certs
module](https://github.com/gruntwork-io/terraform-kubernetes-helm/tree/master/modules/k8s-tiller-tls-certs) to generate
the TLS CA, and a signed certificate key pair for Tiller using that CA. To use this method, set `tiller_tls_gen_method`
to `"provider"`.

When this method is set, the module will call out to `k8s-tiller-tls-certs` to generate TLS certificate key pairs that
are then stored as Kubernetes `Secrets`. Under the hood the
`k8s-tiller-tls-certs` module uses the [tls
provider](https://www.terraform.io/docs/providers/tls/index.html) to generate the TLS certificates, and the [kubernetes
provider](https://www.terraform.io/docs/providers/kubernetes/index.html) to manage the Secrets.

The main advantage of this approach is that everything will be managed in Terraform. This means that you have access to
the full lifecycle of Terraform, including `plan` to see drift and `destroy` to undo your changes.

This method requires specifying the TLS subject info as the `tiller_tls_subject` input map, which is used to generate
the identifying information of the certificate. See
https://www.terraform.io/docs/providers/tls/r/cert_request.html#common_name for a list of expected keys for this map.


#### Generating with kubergrunt

**WARNING: This method requires the `kubergrunt` and `kubectl` binaries to be installed and available. See
https://github.com/gruntwork-io/kubergrunt for installation instructions for `kubergrunt`, and
https://kubernetes.io/docs/tasks/tools/install-kubectl/ for installation instructions for `kubectl`.**

**NOTE: You must have kubergrunt version >=0.5.8**

This method of configuring the TLS certs utilizes [kubergrunt](https://github.com/gruntwork-io/kubergrunt) to generate
the TLS CA, and a signed certificate key pair for Tiller using that CA. To use this method, set `tiller_tls_gen_method`
to `"kubergrunt"`.

When this method is set, the module will call out to `kubergrunt` to generate the TLS certificate key pairs and store
them as Kubernetes `Secrets`. `kubergrunt` handles both steps in a single callout, which keeps the TLS certificates from
leaking into the Terraform state file. The only thing that is stored in the state is the Kubernetes `Secret` references,
not the contents. However, because this uses `null_resources` and an external binary, not all features of Terraform are
available. For example, you can not rely on `plan` to see drift if anything changes about the Kubernetes `Secret`
storing the TLS certs.

This method requires specifying the TLS subject info as the `tiller_tls_subject` input map, which is used to generate
the identifying information of the certificate. See
https://www.terraform.io/docs/providers/tls/r/cert_request.html#common_name for a list of expected keys for this map.

This method also requires configuring authentication to the Kubernetes cluster. Currently `kubergrunt` only supports
either using config contexts, or directly passing in tokens and server info. Note that you can not mix the two methods
(e.g you cannot pull the server info from the context and use a passed in token).

Using config contexts is the default authentication method. When no authentication parameters are set, `kubergrunt` will
load the default context from the default config location (typically `$HOME/.kube/config`). You can control which
context to use using the input variable `kubectl_config_context_name`. You can also specify your config file location
using the input variable `kubectl_config_path`.

If you wish to avoid using the config, you can pass in the server and token info directly. This method is automatically
chosen if the `kubectl_server_endpoint` is provided. Note that `kubectl_ca_b64_data` and `kubectl_token` must also be
provided for this method.


## How do I grant access to other users?

In order to access Tiller, you will typically need to generate additional signed certificates using the generated TLS CA
certs. If you used the direct method, you will have to rely on your certificate provider to sign additional client
certificates. For ther other two methods, you can take a look at [How do you use the generated TLS certs to sign
additional
certificates](https://github.com/gruntwork-io/terraform-kubernetes-helm/tree/master/modules/k8s-tiller-tls-certs/README.md#how-do-you-use-the-generated-tls-certs-to-sign-additional-certificates)
for information on how sign additional certificates using the generated TLS CA.
