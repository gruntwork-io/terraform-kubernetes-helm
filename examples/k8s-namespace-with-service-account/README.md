# K8S Namespace with Service Account

This folder shows an example of how to create a new namespace using the [`k8s-namespace`](/modules/k8s-namespace) module, and create two new `ServiceAccounts`:

- One bound to `namespace-access-all` role
- One bound to `namespace-access-read-only` role

After this example you should have a new namespace with RBAC roles that can be used to grant read-write or read-only
access to the namespace, and two `ServiceAccounts` that are bound to each of the roles.

<!-- Maintainer's note: This example is primarily used for unit testing the underlying module -->

## How do you run this example?

To run this example, apply the Terraform templates:

1. Install [Terraform](https://www.terraform.io/), minimum version: `0.9.7`.
1. Install [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/).
1. Open `variables.tf`, set the environment variables specified at the top of the file, and fill in any other variables
   that don't have a default.
1. Run `terraform init`.
1. Run `terraform apply`.
