[![Maintained by Gruntwork.io](https://img.shields.io/badge/maintained%20by-gruntwork.io-%235849a6.svg)](https://gruntwork.io/?ref=repo_terraform_kubernetes_helm)
[![GitHub tag (latest SemVer)](https://img.shields.io/github/tag/gruntwork-io/terraform-kubernetes-helm.svg?label=latest)](https://github.com/gruntwork-io/terraform-kubernetes-helm/releases/latest)
![Terraform Version](https://img.shields.io/badge/tf-%3E%3D0.12.0-blue.svg)

# Tiller Module

<!-- NOTE: We use absolute linking here instead of relative linking, because the terraform registry does not support
           relative linking correctly.
-->

**DEPRECATION NOTICE: This repo has been deprecated. The Namespace modules have been moved to [terraform-kubernetes-namespace](https://github.com/gruntwork-io/terraform-kubernetes-namespace). Refer to the [v0.1.0](https://github.com/gruntwork-io/terraform-kubernetes-namespace/releases/v0.1.0) release notes for migration instructions. Please use that module for continued functionality of managing Service Accounts and Namespaces.**

**NOTE: This is for deploying Tiller, a major component of Helm v2. Tiller has been removed in Helm v3 and is no longer necesssary. You do NOT need this module to use Helm v3.**

This repo contains a Module for deploying Tiller (the server component of Helm) on Kubernetes clusters with
[Terraform](https://www.terraform.io).  This repo is a part of [the Gruntwork Infrastructure as Code
Library](https://gruntwork.io/infrastructure-as-code-library/), a collection of reusable, battle-tested, production
ready infrastructure code. Read the [Gruntwork
Philosophy](https://github.com/gruntwork-io/terraform-kubernetes-helm/blob/master/GRUNTWORK_PHILOSOPHY.md) document to
learn more about how Gruntwork builds production grade infrastructure code.


## Quickstart Guide

The general idea is to:

1. Deploy a Kubernetes cluster. You can use one of the following:
    - [minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/)
    - [Our GKE module](https://github.com/gruntwork-io/terraform-google-gke/)
    - [Our EKS module](https://github.com/gruntwork-io/terraform-aws-eks/)
1. Setup a `kubectl` config context that is configured to authenticate to the deployed cluster.
1. Install the necessary prerequisites tools:
    - [`helm` client](https://docs.helm.sh/using_helm/#install-helm)
    - (Optional) [`kubergrunt`](https://github.com/gruntwork-io/kubergrunt#installation)
1. Provision a [`Namespace`](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/) and
   [`ServiceAccount`](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/) to house the
   Tiller instance.
1. Deploy Tiller.

You can checkout the [`k8s-tiller-minikube` example
documentation](https://github.com/gruntwork-io/terraform-kubernetes-helm/tree/master/examples/k8s-tiller-minikube) for
detailed instructions on deploying against `minikube`.


## What is in this repo

This repo provides a Gruntwork IaC Package and has the following folder structure:

* [root](https://github.com/gruntwork-io/terraform-kubernetes-helm): The root folder contains an example of how to
  deploy Tiller using [`kubergrunt`](https://github.com/gruntwork-io/kubergrunt), which implements all the logic for
  deploying Tiller with all the security best practices.
* [modules](https://github.com/gruntwork-io/terraform-kubernetes-helm/tree/master/modules): This folder contains the
  main implementation code for this Module, broken down into multiple standalone Submodules.

  The primary module is:

    * [k8s-tiller](https://github.com/gruntwork-io/terraform-kubernetes-helm/tree/master/modules/k8s-tiller): Deploy
      Tiller with all the security features turned on. This includes using `Secrets` for storing state and enabling TLS
      verification.

    The deployed Tiller requires TLS certificate key pairs to operate. Additionally, clients will each need to their
    own TLS certificate key pairs to authenticate to the deployed Tiller instance. This is based on [kubergrunt model of
    deploying helm](https://github.com/gruntwork-io/kubergrunt/blob/master/HELM_GUIDE.md).

    There are also several supporting modules that help with setting up the deployment:

    * [k8s-namespace](https://github.com/gruntwork-io/terraform-kubernetes-helm/tree/master/modules/k8s-namespace):
      Provision a Kubernetes `Namespace` with a default set of RBAC roles.
    * [k8s-namespace-roles](https://github.com/gruntwork-io/terraform-kubernetes-helm/tree/master/modules/k8s-namespace-roles):
      Provision a default set of RBAC roles to use in a `Namespace`.
    * [k8s-service-account](https://github.com/gruntwork-io/terraform-kubernetes-helm/tree/master/modules/k8s-service-account):
      Provision a Kubernetes `ServiceAccount`.
    * [k8s-tiller-tls-certs](https://github.com/gruntwork-io/terraform-kubernetes-helm/tree/master/modules/k8s-tiller-tls-certs):
      Generate a TLS Certificate Authority (CA) and using that, generate signed TLS certificate key pairs that can be
      used for TLS verification of Tiller. The certs are managed on the cluster using Kubernetes `Secrets`. **NOTE**:
      This module uses the `tls` provider, which means the generated certificate key pairs are stored in plain text in
      the Terraform state file. If you are sensitive to secrets in Terraform state, consider using `kubergrunt` for TLS
      management.
    * [k8s-helm-client-tls-certs](https://github.com/gruntwork-io/terraform-kubernetes-helm/tree/master/modules/k8s-helm-client-tls-certs):
      Generate a signed TLS certificate key pair from a previously generated CA certificate key pair. This TLS key pair
      can be used to authenticate a helm client to access a deployed Tiller instance. **NOTE**: This module uses the
      `tls` provider, which means the generated certificate key pairs are stored in plain text in the Terraform state
      file. If you are sensitive to secrets in Terraform state, consider using `kubergrunt` for TLS management.

* [examples](https://github.com/gruntwork-io/terraform-kubernetes-helm/tree/master/examples): This folder contains
  examples of how to use the Submodules.
* [test](https://github.com/gruntwork-io/terraform-kubernetes-helm/tree/master/test): Automated tests for the Submodules
  and examples.


## What is Kubernetes?

[Kubernetes](https://kubernetes.io) is an open source container management system for deploying, scaling, and managing
containerized applications. Kubernetes is built by Google based on their internal proprietary container management
systems (Borg and Omega). Kubernetes provides a cloud agnostic platform to deploy your containerized applications with
built in support for common operational tasks such as replication, autoscaling, self-healing, and rolling deployments.

You can learn more about Kubernetes from [the official documentation](https://kubernetes.io/docs/tutorials/kubernetes-basics/).


## What is Helm?

[Helm](https://helm.sh/) is a package and module manager for Kubernetes that allows you to define, install, and manage
Kubernetes applications as reusable packages called Charts. Helm provides support for official charts in their
repository that contains various applications such as Jenkins, MySQL, and Consul to name a few. Gruntwork uses Helm
under the hood for the Kubernetes modules in this package.

For a background on Helm and its security model, check out [our Helm Guide
document](https://github.com/gruntwork-io/kubergrunt/blob/master/HELM_GUIDE.md).

<!-- TODO: ## What parts of the Production Grade Infrastructure Checklist are covered by this Module? -->


## What's a Module?

A Module is a canonical, reusable, best-practices definition for how to run a single piece of infrastructure, such
as a database or server cluster. Each Module is written using a combination of [Terraform](https://www.terraform.io/)
and scripts (mostly bash) and include automated tests, documentation, and examples. It is maintained both by the open
source community and companies that provide commercial support.

Instead of figuring out the details of how to run a piece of infrastructure from scratch, you can reuse
existing code that has been proven in production. And instead of maintaining all that infrastructure code yourself,
you can leverage the work of the Module community to pick up infrastructure improvements through
a version number bump.


## Who maintains this Module?

This Module and its Submodules are maintained by [Gruntwork](http://www.gruntwork.io/). If you are looking for help or
commercial support, send an email to
[support@gruntwork.io](mailto:support@gruntwork.io?Subject=Tiller%20Module).

Gruntwork can help with:

* Setup, customization, and support for this Module.
* Modules and submodules for other types of infrastructure in major cloud providers, such as VPCs, Docker clusters,
  databases, and continuous integration.
* Modules and Submodules that meet compliance requirements, such as HIPAA.
* Consulting & Training on AWS, GCP, Terraform, and DevOps.


## How do I contribute to this Module?

Contributions are very welcome! Check out the [Contribution
Guidelines](https://github.com/gruntwork-io/terraform-kubernetes-helm/blob/master/CONTRIBUTING.md) for instructions.


## How is this Module versioned?

This Module follows the principles of [Semantic Versioning](http://semver.org/). You can find each new release, along
with the changelog, in the [Releases Page](https://github.com/gruntwork-io/terraform-kubernetes-helm/releases).

During initial development, the major version will be 0 (e.g., `0.x.y`), which indicates the code does not yet have a
stable API. Once we hit `1.0.0`, we will make every effort to maintain a backwards compatible API and use the MAJOR,
MINOR, and PATCH versions on each release to indicate any incompatibilities.


## License

Please see [LICENSE](https://github.com/gruntwork-io/terraform-kubernetes-helm/blob/master/LICENSE) for how the code in
this repo is licensed.

Copyright &copy; 2019 Gruntwork, Inc.
