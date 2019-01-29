# K8S Tiller

This folder shows an example of a best practices way of deploying Tiller (the server component of Helm) on your
Kubernetes cluster. This means:

- Create a namespace to house the Tiller deployment (Tiller namespace)
- Create a namespace to house the resources that Tiller should manage (resource namespace)
- Create a ServiceAccount with admin access to both namespaces that Tiller will bind to.
- Deploy Tiller

After this example, you will have a Tiller deployment in the Tiller namespace that is locked down with TLS verification
turned on.

You can then use `kubergrunt` to configure access to Tiller for your helm clients (assuming you granted access to the
RBAC entity):

```
kubergrunt helm configure --home-dir $HOME/.helm --tiller-namespace TILLER_NAMESPACE --rbac-user USER
```


## How do you run this example?

To run this example, install `kubergrunt` and apply the Terraform templates:

1. Install [Terraform](https://www.terraform.io/), minimum version: `0.9.7`.
1. Install [kubergrunt](https://github.com/gruntwork-io/kubergrunt).
1. Install [helm CLI](https://docs.helm.sh/using_helm/#install-helm).
1. (Optional) Install [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/).
1. Open `variables.tf`, set the environment variables specified at the top of the file, and fill in any other variables
   that don't have a default.
1. Run `terraform init`.
1. Run `terraform apply`.
