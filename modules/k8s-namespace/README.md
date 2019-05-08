# K8S Namespace Module

<!-- NOTE: We use absolute linking here instead of relative linking, because the terraform registry does not support
           relative linking correctly.
-->

This Terraform Module manages Kubernetes
[`Namespaces`](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/). In addition to creating
namespaces, this module will create a set of default RBAC roles restricted to that namespace. The following roles will
be provided by this module:

- `namespace-access-all`: Admin level permissions in the namespace. Ability to read, write, and delete all resources in
  the namespace.
- `namespace-access-read-only`: Read only permissions to all resources in the namespace.
- `namespace-tiller-metadata-access`: Minimal permissions for Tiller to manage its metadata in this namespace (if this
  namespace is where Tiller is deployed).
- `namespace-tiller-resource-access`: Minimal permissions for Tiller to manage resources in this namespace as Helm
  charts.  


## How do you use this module?

* See the [root README](https://github.com/gruntwork-io/terraform-kubernetes-helm/blob/master/README.md) for instructions on using Terraform modules.
* This module uses [the `kubernetes` provider](https://www.terraform.io/docs/providers/kubernetes/index.html).
* See the [examples](https://github.com/gruntwork-io/terraform-kubernetes-helm/tree/master/examples) folder for example
  usage.
* See [variables.tf](https://github.com/gruntwork-io/terraform-kubernetes-helm/blob/master/modules/k8s-namespace/variables.tf)
  for all the variables you can set on this module.
* See [outputs.tf](https://github.com/gruntwork-io/terraform-kubernetes-helm/blob/master/modules/k8s-namespace/outputs.tf)
  for all the variables that are outputed by this module.


## What is a Namespace?

A `Namespace` is a Kubernetes resource that can be used to create a virtual environment in your cluster to separate 
resources. It allows you to scope resources in your cluster to provide finer grained permission control and resource
quotas.

For example, suppose that you have two different teams managing separate services independently, such that the team
should not be allowed to update or modify the other teams' services. In such a scenario, you would use namespaces to
separate the resources between each team, and implement RBAC roles that only grant access to the namespace if you reside
in the team that manages it.

To illustrate this, let's assume that we have a team that manages
the application services related to the core product (named `core`) and another team managing analytics services (named
`analytics`). Let's also assume that we have already created RBAC groups for each team, named `core-group` and
`analytics-group`.

We create the namespaces using this module:

```
module "core_namespace" {
  source = "git::https://github.com/gruntwork-io/terraform-kubernetes-helm.git//modules/k8s-namespace?ref=v0.1.0"
  name = "core"
}

module "analytics_namespace" {
  source = "git::https://github.com/gruntwork-io/terraform-kubernetes-helm.git//modules/k8s-namespace?ref=v0.1.0"
  name = "analytics"
}
```

In addition to creating namespaces, this will also create a set of RBAC roles that can then be bound to user and group
entities to explicitly grant permissions to access that namespace.

We can then use `kubectl` to bind the roles to the groups:
```
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: core-role-binding
  namespace: core
subjects:
- kind: Group
  name: core
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: core-access-all
  apiGroup: rbac.authorization.k8s.io
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: analytics-role-binding
  namespace: analytics
subjects:
- kind: Group
  name: analytics
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: analytics-access-all
  apiGroup: rbac.authorization.k8s.io
```

When we apply this config with `kubectl`, users that are associated with the `core` RBAC group can now create and access
resources deployed in the `core` namespace, and the `analytics` group can access resources in the `analytics` namespace.
However, members of the `core` team can not access resources in the `analytics` namespace and vice versa.

To summarize, use namespaces to:

- Implement finer grained access control over deployed resources.
- Implement [resource quotas](https://kubernetes.io/docs/concepts/policy/resource-quotas/) to restrict how much of the
  cluster can be utilized by each team.


## Why is this a Terraform Module and not a Helm Chart?

This module uses Terraform to manage the `Namespace` and RBAC role resources instead of using Helm to support the use case of
setting up Helm. When setting up the Helm server, you will want to setup a `Namespace` and `ServiceAccount` for the Helm
server to be deployed with. This leads to a chicken and egg problem, where the `Namespace` and `ServiceAccount` needs to
be created before Helm is available for use. As such, we rely on Terraform to set these core resources up.
