# K8S Namespace Roles Module

<!-- NOTE: We use absolute linking here instead of relative linking, because the terraform registry does not support
           relative linking correctly.
-->

This Terraform Module defines a set of common Kubernetes
[RBAC `Roles`](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) for a `Namespace`. The following roles
will be provided by this module:

- `namespace-access-all`: Admin level permissions in the namespace. Ability to read, write, and delete all resources in
  the namespace.
- `namespace-access-read-only`: Read only permissions to all resources in the namespace.
- `namespace-tiller-metadata-access`: Minimal permissions for Tiller to manage its metadata in this namespace (if this
  namespace is where Tiller is deployed).
- `namespace-tiller-resource-access`: Minimal permissions for Tiller to manage resources in this namespace as Helm
  charts.  


## How do you use this module?

* See the [root README](https://github.com/gruntwork-io/terraform-kubernetes-helm/blob/master/README.md) for
  instructions on using Terraform modules.
* This module uses [the `kubernetes` provider](https://www.terraform.io/docs/providers/kubernetes/index.html).
* See the [examples](https://github.com/gruntwork-io/terraform-kubernetes-helm/tree/master/examples) folder for example
  usage.
* See [variables.tf](https://github.com/gruntwork-io/terraform-kubernetes-helm/blob/master/modules/k8s-namespace-roles/variables.tf)
  for all the variables you can set on this module.
* See [outputs.tf](https://github.com/gruntwork-io/terraform-kubernetes-helm/blob/master/modules/k8s-namespace-roles/outputs.tf)
  for all the variables that are outputed by this module.


## What is Kubernetes Role Based Access Control (RBAC)?

[Role Based Access Control (RBAC)](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) is a method to regulate
access to resources based on the role that individual users assume in an organization. Kubernetes allows you to define
roles in the system that individual users inherit, and explicitly grant permissions to resources within the system to
those roles. The Control Plane will then honor those permissions when accessing the resources on Kubernetes through
clients such as `kubectl`. When combined with namespaces, you can implement sophisticated control schemes that limit the
access of resources across the roles in your organization.

The RBAC system is managed using `ClusterRole` and `ClusterRoleBinding` resources (or `Role` and `RoleBinding` resources
if restricting to a single namespace). The `ClusterRole` (or `Role`) object defines a role in the Kubernetes system that
has explicit permissions on what it can and cannot do. These roles are then bound to users and groups using the
`ClusterRoleBinding` (or `RoleBinding`) resource. An important thing to note here is that you do not explicitly create
users and groups using RBAC, and instead rely on the authentication system to implicitly create these entities.  

Refer to [the official documentation](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) for more
information.


## How do you bind the Roles?

This module will create a set of RBAC roles that can then be bound to user and group entities to explicitly grant
permissions to access that namespace.

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


## Why is this a Terraform Module and not a Helm Chart?

This module uses Terraform to manage the `Namespace` and RBAC role resources instead of using Helm to support the use case of
setting up Helm. When setting up the Helm server, you will want to setup a `Namespace` and `ServiceAccount` for the Helm
server to be deployed with. This leads to a chicken and egg problem, where the `Namespace` and `ServiceAccount` needs to
be created before Helm is available for use. As such, we rely on Terraform to set these core resources up.
