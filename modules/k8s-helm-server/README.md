# K8S Helm Server Module

This Terraform Module manages Helm Servers (also known as Tiller) deployments on your targetted Kubernetes clusters.
This module can be used to declaratively deploy and manage multiple Tiller deployments in a single Kubernetes cluster.
Unlike the defaults installed by the helm client, the deployed Tiller instances:

- Use Kubernetes Secrets instead of ConfigMaps for storing release information.
- Are restricted to the provided namespace.
- Enable TLS, allocating a set of base credentials for the operator to use (more can be added later).


## How do you use this module?

* See the [root README](/README.md) for instructions on using Terraform modules.
* This module uses [the `kubernetes` provider](https://www.terraform.io/docs/providers/kubernetes/index.html).
* See the [examples](/examples) folder for example usage.
* See [variables.tf](./variables.tf) for all the variables you can set on this module.
* See [outputs.tf](./outputs.tf) for all the variables that are outputed by this module.
* This module depends on [`kubergrunt`](https://github.com/gruntwork-io/kubergrunt). Refer to the `kubergrunt`
  documentation for installation instructions.


## Security Model of Helm Server (Tiller)

By design, Tiller is the responsible entity in Helm to apply the Kubernetes config against the cluster. What this means
is that Tiller needs enough permissions in the Kubernetes cluster to be able to do anything requested by a Helm chart.
These permissions are granted to Tiller through the use of `ServiceAccounts`, which are credentials that a Kubernetes
pod can inherit when making calls to the Kubernetes server.

Currently there is no way for Tiller to be able to inherit the permissions of the calling entity (e.g the user accessing
the server via the Helm client). In practice, this means that any user who has access to the Tiller server is able to
gain the same permissions granted to that server even though their RBAC roles may be more restrictive. In other words,
if Tiller has admin permissions (the default), then all users that have access to it via helm effectively has admin
permissions on the Kubernetes cluster.

Tiller provides two mechanisms to handle the permissions given their design:

- Using `ServiceAccounts` to restrict what Tiller can do
- Using TLS based authentication to restrict who has access to the Tiller server

This module provides utilities that help support this security model.

### Client Authentication

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

This module will generate the Tiller and CA TLS certificates for each Tiller install and store the certificates in a
Secret on the Kubernetes cluster. The Secrets are then shared with RBAC groups so that authorized users can access the
certificates to manage client access. By default this is limited to those in those who have cluster admin access
(superusers). Additional RBAC roles can be granted access by using the `ca_certificate_rbac_roles` and the
`tiller_certificate_rbac_roles` input variables to the module.

### Service Account

Tiller relies on `ServiceAccounts` and the associated RBAC roles to properly restrict what Helm Charts can do. The RBAC
system in Kubernetes allows the operator to define fine grained permissions on what an individual or system can do in
the cluster. By using RBAC, you can restrict Tiller installs to only manage resources in particular namespaces, or even
restrict what resources Tiller can manage.

This module requires a `ServiceAccount` to use for Tiller, specified by the `service_account` input variable. The
roles for the `ServiceAccount` is managed outside of this module. See the [secure-helm example](/examples/secure-helm)
for example usage.

At a minimum, each Tiller server should be deployed in its own namespace to manage the resources in that namespace, and
restricted to only be able to access that namespace. This can be done by creating a `ServiceAccount` limited to that
namespace:

```yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: dev-service-account
  labels:
    app: tiller
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1alpha1
metadata:
  namespace: dev
  name: dev-all
rules:
  - apiGroups: ["*"]
    resources: ["*"]
    verbs: ["*"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1alpha1
metadata:
  name: dev-role-dev-all-members
  namespace: dev
subjects:
  - kind: Group
    name: system:serviceaccounts:dev-service-account
roleRef:
  kind: Role
  name: dev-all
  apiGroup: "rbac.authorization.k8s.io"
```

This resource configuration creates a new `ServiceAccount` named `dev-service-account`, a new RBAC `Role` named
`dev-all` with permissions to do anything in the `dev` namespace, and `RoleBinding` that ties the two together.

## Threat model

As discussed above, Tiller does not provide a way to inherit permissions of the calling entity. This means that you can
not rely on your RBAC configurations of the user to restrict what they can deploy through helm.

To illustrate this, consider the following example:

Suppose that you have installed Tiller naively using the defaults, but configured it to use TLS authentication based on
the documentation. You configured Tiller with a pair of TLS certificates that you shared with your developers so that
they can access the server to use Helm. Note that a default Tiller install has admin level permissions on the Kubernetes
cluster (a `ServiceAccount` with permissions in the `kube-system` namespace) to be able to do almost anything in
the cluster.

Suppose further that you originally wanted to restrict your developers from being able to access `Secrets` created in a
particular namespace called `secret`. You had originally implemented RBAC roles that prevented accessing this namespace
for Kubernetes users in the group `developers`. All your developers have credentials that map to the `developers` group
in Kubernetes. You have verified that they can not access this namespace using `kubectl`.

In this scenario, Tiller poses a security risk to your team. Specifically, because Tiller has been deployed with admin
level permissions in the cluster, and because your developers have access to Tiller via Helm, your developers are now
able to deploy Helm charts that perform certain actions in the `secret` namespace despite not being able to directly
access it. This is because Tiller is the entity that is actually applying the configs from the rendered Helm charts.
This means that the configs are being applied with Tiller's credentials as opposed to the developer credentials. As
such, your developers can deploy a pod that has access to `Secrets` created in the `secret` namespace and potentially
read the information stored there by having the pod send the data to some arbitrary endpoint (or another pod in the
system), bypassing the RBAC restrictions you have created.

Therefore, it is important that the Tiller servers that your team has access to is deployed with `ServiceAccounts` that
maintain a strict subset of the permissions granted to the users. This means that you potentially need one Tiller server
per RBAC role in your Kubernetes cluster.

It is also important to lock down access to the TLS certs used to authenticate against the various Tiller servers
deployed in your Kubernetes environment, so that your users can only access the Tiller deployment that maps to their
permissions. Each of the key pairs have varying degrees of severity when compromised:

- If you possess the CA key pair, then you can issue additional certificates to pose as **both** Tiller and the client.
  This means that you can:
    - Trick the client in installing charts with secrets to a compromised Tiller server that could forward it to a
      malicious entity.
    - Trick Tiller into believing a client has access and install malicious Pods on the Kubernetes cluster.

- If you possess the Tiller key pair, then you can pose as Tiller to trick a client in installing charts on a compromised
  Tiller server.
- If you possess the client key pair, then you can pose as the client and install malicious charts on the Kubernetes
  cluster.


## How do I grant access to the deployed Tiller instance?

As mentioned in the [Client Authentication section](#client-authentication), a TLS certificate key pair needs to be
issued using the installed CA to grant access to helm clients to access the Tiller server. This means that, at a
minimum, you need to be a privileged user with access to the CA key pair. By default this is restricted to cluster admin
users.

As a cluster admin user, you can then use the CA key pair to issue a new key pair that is then shared with the helm
client. At a high level, the process is:

- Download the CA key pair from Kubernetes.
- Issue a new TLS certificate key pair using the CA key pair.
- Upload the new TLS certificate key pair to a new Secret in a new Namespace that only the granted RBAC role has access
  to.
- Remove the local copies of the downloaded and generated certificates.
- The client then downloads the new TLS certificate key pair and configures the local helm client.

We provide a [subcommand in `kubergrunt`](../kubergrunt/README.md#grant) to automate this process, so that everything up
to and including uploading the TLS certificates back to Kubernetes can be done in one command:

```
kubergrunt helm grant --tiller-namespace NAMESPACE_OF_TILLER_TO_GRANT_ACCESS_TO --rbac-role ROLE_THAT_SHOULD_HAVE_ACCESS
```

This command will create a new namespace that hyphen concatenates the tiller namespace with the granted rbac role that
will house a `Secret` resource named `tiller-client-keypair` that the client can then download and use.

We also provide a subcommand to revoke access as well:

```
kubergrunt helm revoke --tiller-namespace NAMESPACE_OF_TILLER_TO_GRANT_ACCESS_TO --rbac-role ROLE_THAT_SHOULD_HAVE_ACCESS
```
