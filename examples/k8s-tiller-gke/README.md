# Kubernetes Tiller Deployment On Google Kubernetes Engine

This example shows how to use Terraform to call out to our `kubergrunt` utility in order to deploy Tiller (the server
component of Helm) onto a Google Kubernetes Engine cluster.


## Background

We strongly recommend reading [our guide on Helm](https://github.com/gruntwork-io/kubergrunt/blob/master/HELM_GUIDE.md)
before continuing with this guide for a background on Helm, Tiller, and the security model backing it.


## Overview

In this guide we will walk through the steps necessary to get up and running with deploying Tiller on GKE using this 
module. Here are the steps:

1. [Install the necessary tools](#installing-necessary-tools)
1. [Deploy a GKE cluster](#deploying-a-gke-cluster)
1. [Apply the Terraform code](#apply-the-terraform-code)
1. [Verify the deployment](#verify-tiller-deployment)
1. [Granting access to additional roles](#granting-access-to-additional-users)
1. [Upgrading the deployed Tiller instance](#upgrading-deployed-tiller)

## Installing necessary tools

In addition to `terraform`, this guide relies on the `gcloud` and `kubectl` tools to manage the cluster. In addition
we use `kubergrunt` to manage the deployment of Tiller. You can read more about  the decision behind this approach in
[the Appendix](#appendix-a-why-kubergrunt) of this guide.

This means that your system needs to be configured to be able to find `terraform`, `gcloud`, `kubectl`, `kubergrunt`,
and `helm` client utilities on the system `PATH`. Here are the installation guide for each tool:

1. [`gcloud`](https://cloud.google.com/sdk/gcloud/)
1. [`kubectl`](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
1. [`terraform`](https://learn.hashicorp.com/terraform/getting-started/install.html)
1. [`helm` client](https://docs.helm.sh/using_helm/#installing-helm)
1. [`kubergrunt`](https://github.com/gruntwork-io/kubergrunt#installation)

Make sure the binaries are discoverable in your `PATH` variable. See [this Stack Overflow
post](https://stackoverflow.com/questions/14637979/how-to-permanently-set-path-on-linux-unix) for instructions on
setting up your `PATH` on Unix, and [this
post](https://stackoverflow.com/questions/1618280/where-can-i-set-path-to-make-exe-on-windows) for instructions on
Windows.

## Deploying a GKE Cluster

You can use one of our examples to deploy a GKE cluster on Google Cloud.

```bash
$ cd examples/gke-regional-public-cluster
$ terraform init
$ terraform plan -var project=$GOOGLE_CLOUD_PROJECT -var region=europe-west3
$ terraform apply -var project=$GOOGLE_CLOUD_PROJECT -var region=europe-west3
```

Then configure `kubectl` to point to the new cluster:

```bash
$ gcloud beta container clusters get-credentials example-cluster --region europe-west3 --project $GOOGLE_CLOUD_PROJECT
```

You can verify the setup and test cluster authentication with:

```bash
$ kubectl cluster-info
$ kubectl auth can-i create roles -n kube-system
```

We need to configure the role binding accordingly:

```bash
$ kubectl create clusterrolebinding cluster-admin-binding --clusterrole cluster-admin --user rob@gruntwork.io
```

## Apply the Terraform Code

Now that we have a working Google Kubernetes Engine cluster, and all the prerequisite tools are installed, we are ready
to deploy Tiller! To deploy Tiller, we will use the example Terraform code at the root of this repo:

1. If you haven't already, clone this repo:
    - `git clone https://github.com/gruntwork-io/terraform-kubernetes-helm.git`
1. Make sure you are at the root of this repo:
    - `cd terraform-kubernetes-helm`
1. Initialize terraform:
    - `terraform init`
1. Check the terraform plan:
    - `terraform plan -var kubectl_config_context_name=$(kubectl config current-context)`
1. Apply the terraform code:
    - `terraform apply -var kubectl_config_context_name=$(kubectl config current-context)`
    - Fill in the required variables based on your needs. <!-- TODO: show example inputs here -->

The Terraform code creates a few resources before deploying Tiller using `kubergrunt`:

- A Kubernetes `Namespace` (the `tiller-namespace`) to house the Tiller instance. This namespace is where all the
  Kubernetes resources that Tiller needs to function will live. In production, you will want to lock down access to this
  namespace as being able to access these resources can compromise all the protections built into Helm.
- A Kubernetes `Namespace` (the `resource-namespace`) to house the resources deployed by Tiller. This namespace is where
  all the Helm chart resources will be deployed into. This is the namespace that your devs and users will have access
  to.
- A Kubernetes `ServiceAccount` (`tiller-service-account`) that Tiller will use to apply the resources in Helm charts.
  Our Terraform code grants enough permissions to the `ServiceAccount` to be able to have full access to both the
  `tiller-namespace` and the `resource-namespace`, so that it can:
    - Manage its own resources in the `tiller-namespace`, where the Tiller metadata (e.g release tracking information) will live.
    - Manage the resources deployed by helm charts in the `resource-namespace`.

Then it will feed the names of the created resources into the `kubergrunt helm deploy` command. As part of the
deployment, `kubergrunt` will:

- Create a new TLS certificate key pair to use as the CA and upload it to Kubernetes as a `Secret` in the `kube-system`
  namespace.
- Using the generated CA TLS certificate key pair, create a signed TLS certificate key pair to use to identify the
  Tiller server and upload it to Kubernetes as a `Secret` in the `tiller-namespace`.
- Deploy Tiller with the following configurations turned on:
    - TLS verification
    - `Secrets` as the storage engine
    - Provisioned in the `tiller-namespace` with the service account as the `tiller-service-account`

- Grant access to the provided RBAC entity and configure the local helm client to use those credentials:
    - Using the CA TLS certificate key pair, create a signed TLS certificate key pair to use to identify the client.
    - Upload the certificate key pair to the `tiller-namespace`.
    - Grant the RBAC entity access to:
        - Get the client certificate `Secret` (`kubergrunt helm configure` uses this to install the client certificate
          key pair locally)
        - Get and List pods in `tiller-namespace` (the `helm` client uses this to find the Tiller pod)
        - Create a port forward to the Tiller pod (the `helm` client uses this to make requests to the Tiller pod)

    - Install the client certificate key pair to the helm home directory so the client can use it.

You should now have a working Tiller deployment with your helm client configured to access it.
So let's verify that in the next step!


## Verify Tiller Deployment

To start using `helm` with the configured credentials, you need to specify the following things:

- enable TLS verification
- use TLS credentials to authenticate
- the namespace where Tiller is deployed

These are specified through command line arguments. If everything is configured correctly, you should be able to access
the Tiller that was deployed with the following args:

```
helm --tls --tls-verify --tiller-namespace NAMESPACE_OF_TILLER version
```

If you have access to Tiller, this should return you both the client version and the server version of Helm.

Note that you need to pass the above CLI argument every time you want to use `helm`. This can be cumbersome, so
`kubergrunt` installs an environment file into your helm home directory that you can dot source to set environment
variables that guide `helm` to use those options:

```
. ~/.helm/env
helm version
```

<!-- TODO: Mention windows -->

## Install an Example Chart

Let's use Helm to install Jenkins:

```bash
$ 
```

And destroy:

```bash
$ terraform destroy -var kubectl_config_context_name=$(kubectl config current-context) -var force_undeploy=true
```

**Warning:** Exposing Jenkins on the public internet. <!-- TODO - pick safer chart -->

## Granting Access to Additional Users

Now that you have deployed Tiller and setup access for your local machine, you are ready to start using `helm`! However,
you might be wondering how do you share the access with your team? To do so, you can rely on `kubergrunt helm grant`.

In order to allow other users access to the deployed Tiller instance, you need to explicitly grant their RBAC entities
permission to access it. This involves:

- Granting enough permissions to access the Tiller pod
- Generating and sharing TLS certificate key pairs to identify the client

`kubergrunt` automates this process in the `grant` and `configure` commands. For example, suppose you wanted to grant
access to the deployed Tiller to a group of users grouped under the RBAC group `dev`. You can grant them access using
the following command:

```
kubergrunt helm grant --tiller-namespace NAMESPACE_OF_TILLER --rbac-group dev --tls-common-name dev --tls-org YOUR_ORG
```

This will generate a new certificate key pair for the client and upload it as a `Secret`. Then, it will bind new RBAC
roles to the `dev` RBAC group that grants it permission to access the Tiller pod and the uploaded `Secret`.

This in turn allows your users to configure their local client using `kubergrunt`:

```
kubergrunt helm configure --tiller-namespace NAMESPACE_OF_TILLER --rbac-group dev
```

At the end of this, your users should have the same helm client setup as above.


## Upgrading Deployed Tiller

At some point in the lifetime of the Tiller deployment, you will want to upgrade it. You can upgrade the deployed Tiller
instance using the helm client with the following command:

```
helm init --upgrade --tiller-namespace TILLER_NAMESPACE
```

**Note**: You need to be an administrator to run this command. Specifically, this should be done with the same `kubectl`
context as the one used to deploy Tiller. You can use the `--kube-context` option to use a different context from the
default.


## Appendix A: Why kubergrunt?

This Terraform example is not idiomatic Terraform code in that it relies on an external binary, `kubergrunt` as opposed
to implementing the functionalities using pure Terraform providers. This approach has some noticeable drawbacks:

- You have to install extra tools to use, so it is not a minimal `terraform init && terraform apply`.
- Portability concerns to setup, as there is no guarantee the tools work cross platform. We make every effort to test
  across the major operating systems (Linux, Mac OSX, and Windows), but we can't possibly test every combination and so
  there are bound to be portability issues.
- You don't have the declarative Terraform features that you come to love, such as `plan`, updates through `apply`, and
  `destroy`.

That said, we decided to use this approach because of limitations in the existing providers to implement the
functionalities here in pure Terraform code:

- The Helm provider does not have [a resource that manages
  Tiller](https://github.com/terraform-providers/terraform-provider-helm/issues/134).
- The [TLS provider](https://www.terraform.io/docs/providers/tls/index.html) stores the certificate key pairs in plain
  text into the Terraform state.
- The Kubernetes Secret resource in the provider [also stores the value in plain text in the Terraform
  state](https://www.terraform.io/docs/providers/kubernetes/r/secret.html).
- The grant and configure workflows are better suited as CLI tools than in Terraform.

Note that [we intend to implement a pure Terraform version of this when the Helm provider is
updated](https://github.com/gruntwork-io/terraform-kubernetes-helm/issues/13), but we plan to continue to maintain the
`kubergrunt` approach for folks who are wary of leaking secrets into Terraform state.
