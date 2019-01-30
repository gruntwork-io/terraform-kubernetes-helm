# K8S Tiller

This folder shows an example of how to deploy Tiller (the server component of Helm) on your Kubernetes cluster following
the best practices for securing access.

This guide requires a Kubernetes instance. You can either use:

- [minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/)
- [Kubernetes on Docker for Mac](https://docs.docker.com/docker-for-mac/kubernetes/)
- EKS
- GKE


## How do you run this example?

In addition to Terraform, this example depends on modules that use the
[`kubergrunt`](https://github.com/gruntwork-io/kubergrunt) utility under the hood.

To run this example, apply the Terraform templates:

1. Install [Terraform](https://www.terraform.io/), minimum version: `0.9.7`.
1. Install [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/).
1. Install [helm client](https://docs.helm.sh/using_helm/#install-helm)
1. Install [kubergrunt](https://github.com/gruntwork-io/kubergrunt)
1. Open `variables.tf`, set the environment variables specified at the top of the file, and fill in any other variables
   that don't have a default.
1. Run `terraform init`.
1. Run `terraform apply`.
