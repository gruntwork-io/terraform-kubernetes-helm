[![Maintained by Gruntwork.io](https://img.shields.io/badge/maintained%20by-gruntwork.io-%235849a6.svg)](https://gruntwork.io/?ref=repo_terraform_kubernetes_helm)

# Helm Server Module

This repo contains a Module for deploying Helm Server on Kubernetes clusters with [Terraform](https://www.terraform.io). 
This repo is a part of [the Gruntwork Infrastructure as Code
Library](https://gruntwork.io/infrastructure-as-code-library/), a collection of reusable, battle-tested, production
ready infrastructure code. Read the [Gruntwork Philosophy](GRUNTWORK_PHILOSOPHY.md) document to learn more about how
Gruntwork builds production grade infrastructure code.


## What is in this repo

This repo provides a Gruntwork IaC Package and has the following folder structure:

* [modules](/modules): This folder contains the main implementation code for this Module, broken down into multiple
  standalone Submodules.
* [examples](/examples): This folder contains examples of how to use the Submodules. The [example root
  README](/examples/README.md) provides a quickstart guide on how to use the Submodules in this Module.
* [test](/test): Automated tests for the Submodules and examples.

The following submodules are available in this module:

- [k8s-namespace](/modules/k8s-namespace): Provision a Kubernetes `Namespace` with a default set of RBAC roles.
- [k8s-service-account](/modules/k8s-service-account): Provision a Kubernetes `ServiceAccount`.
- [k8s-helm-server](/modules/k8s-helm-server): Provision a namespaced secure Helm Server on an existing Kubernetes
  cluster.

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

Helm consists of two components: the Helm Client, and the Helm Server (Tiller)

### What is the Helm Client?

The Helm client is a command line utility that provides a way to interact with Tiller. It is the primary interface to
installing and managing Charts as releases in the Helm ecosystem. In addition to providing operational interfaces (e.g
install, upgrade, list, etc), the client also provides utilities to support local development of Charts in the form of a
scaffolding command and repository management (e.g uploading a Chart).

### What is the Helm Server?

The Helm Server (Tiller) is a component of Helm that runs inside the Kubernetes cluster. Tiller is what
provides the functionality to apply the Kubernetes resource descriptions to the Kubernetes cluster. When you install a
release, the helm client essentially packages up the values and charts as a release, which is submitted to Tiller.
Tiller will then generate Kubernetes YAML files from the packaged release, and then apply the generated Kubernetes YAML
file from the charts on the cluster.

<!-- TODO: ## What parts of the Production Grade Infrastructure Checklist are covered by this Module? -->


## Who maintains this Module?

This Module and its Submodules are maintained by [Gruntwork](http://www.gruntwork.io/). If you are looking for help or
commercial support, send an email to
[support@gruntwork.io](mailto:support@gruntwork.io?Subject=Tiller%20Module).

Gruntwork can help with:

* Setup, customization, and support for this Module.
* Modules and submodules for other types of infrastructure, such as VPCs, Docker clusters, databases, and continuous
  integration.
* Modules and Submodules that meet compliance requirements, such as HIPAA.
* Consulting & Training on AWS, Terraform, and DevOps.


## How do I contribute to this Module?

Contributions are very welcome! Check out the [Contribution Guidelines](/CONTRIBUTING.md) for instructions.


## How is this Module versioned?

This Module follows the principles of [Semantic Versioning](http://semver.org/). You can find each new release, along
with the changelog, in the [Releases Page](../../releases).

During initial development, the major version will be 0 (e.g., `0.x.y`), which indicates the code does not yet have a
stable API. Once we hit `1.0.0`, we will make every effort to maintain a backwards compatible API and use the MAJOR,
MINOR, and PATCH versions on each release to indicate any incompatibilities.


## License

Please see [LICENSE](/LICENSE) for how the code in this repo is licensed.

Copyright &copy; 2019 Gruntwork, Inc.
