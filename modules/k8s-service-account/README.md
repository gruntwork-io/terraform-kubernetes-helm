# K8S ServiceAccount Module

<!-- NOTE: We use absolute linking here instead of relative linking, because the terraform registry does not support
           relative linking correctly.
-->

This Terraform Module manages Kubernetes
[`ServiceAccounts`](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/). This module
can be used to declaratively create and update `ServiceAccounts` and the bound permissions that it has.


## How do you use this module?

* See the [root README](https://github.com/gruntwork-io/terraform-kubernetes-helm/blob/master/README.md) for
  instructions on using Terraform modules.
* This module uses [the `kubernetes` provider](https://www.terraform.io/docs/providers/kubernetes/index.html).
* See the [examples](https://github.com/gruntwork-io/terraform-kubernetes-helm/tree/master/examples) folder for example
  usage.
* See [variables.tf](https://github.com/gruntwork-io/terraform-kubernetes-helm/blob/master/modules/k8s-service-account/variables.tf)
  for all the variables you can set on this module.
* See [outputs.tf](https://github.com/gruntwork-io/terraform-kubernetes-helm/blob/master/modules/k8s-service-account/outputs.tf)
  for all the variables that are outputed by this module.


## What is a ServiceAccount?

`ServiceAccounts` are authenticated entities to the Kubernetes API that map to container processes in a Pod. This is
used to differentiate from User Accounts, which map to actual users consuming the  Kubernetes API.

`ServiceAccounts` are allocated to Pods at creation time, and automatically authenticated when calling out to the
Kubernetes API from within the Pod. This has several advantages:

- You don't need to share and configure secrets for the Kubernetes API client.
- You can restrict permissions on the service to only those that it needs.
- You can differentiate a service accessing the API and performing actions from users accessing the API.

Use `ServiceAccounts` whenever you need to grant access to the Kubernetes API to Pods deployed on the cluster.


## Why is this a Terraform Module and not a Helm Chart?

This module uses Terraform to manage the `ServiceAccount` resource instead of using Helm to support the use case of
setting up Helm. When setting up the Helm server, you will want to setup a `Namespace` and `ServiceAccount` for the Helm
server to be deployed with. This leads to a chicken and egg problem, where the `Namespace` and `ServiceAccount` needs to
be created before Helm is available for use. As such, we rely on Terraform to set these core resources up.
