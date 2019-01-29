# K8S Tiller (Helm Server) Module

This Terraform Module manages Tiller (the server component of Helm) deployments on your targetted Kubernetes clusters.
This module can be used to declaratively deploy and manage multiple Tiller deployments in a single Kubernetes cluster.
Unlike the defaults installed by the helm client, the deployed Tiller instances:

- Use Kubernetes Secrets instead of ConfigMaps for storing release information.
- Are restricted to the provided namespace.
- Enable TLS, allocating a set of base credentials for the operator to use (more can be added later).

Note: Please be advised that there are plans by the community to deprecate and remove Tiller starting Helm v3. This
repository will be updated with migration instructions to help smooth out the upgrade when Helm v3 lands.


## How do you use this module?

* See the [root README](/README.md) for instructions on using Terraform modules.
* See the [examples](/examples) folder for example usage.
* See [variables.tf](./variables.tf) for all the variables you can set on this module.
* See [outputs.tf](./outputs.tf) for all the variables that are outputed by this module.
* `kubectl` must be configured to authenticate against the target Kubernetes cluster.
* This module uses the `kubergrunt` utility under the hood to deploy Tiller. See [the
  documentation](https://github.com/gruntwork-io/kubergrunt) for more information.


## Why does this depend on an external tool?

This module depends on an external tool ([`kubergrunt`](https://github.com/gruntwork-io/kubergrunt)) to drive the
deployment of Tiller. We took this approach to solve the following requirements:

- A way to generate TLS certificates for server and client auth.
- A way to manage client certificates (granting and revoking access).
- Avoid leaking sensitive information (e.g certificates) into the terraform state.
- Be portable across platforms (Linux, Mac OSX, Windows).

None of the existing solutions quite satisfied all our constraints. Additionally, many of the standard resources in the
existing terraform providers leaked sensitive information into the terraform state. We reached the conclusion that
Terraform may not be best suited for the purpose of TLS certificate management, and instead we should rely on a script.

We considered a few scripting options, but ultimately landed on implementing the tool in Go. This is primarily for Go's strengths
around cross compilation and portability, as well as its dependency management. Here are the alternatives we considered:

- `bash` + `openssl`: While great for Unix scripting, does not support typical Windows environments.
- `python`: While great on platform portability, version (python 2 vs 3) and dependency portability (installing
  dependencies requires a 3rd party tool and additional installation step) are weaker compared to Go.


## Differences with the helm provider based Tiller install

There are a few enhancements in this module compared to setting up a Tiller install using [the `helm`
provider](https://www.terraform.io/docs/providers/helm/index.html#install_tiller). Eventually this will reduce down to
the TLS certificate management when [Tiller is turned into a
resource](https://github.com/terraform-providers/terraform-provider-helm/issues/134):

### Automatic TLS generation

By leveraging `kubergrunt`, this module is able to generate and manage TLS certificates as part of the install process
without leaking it into the terraform state (e.g see [warning on the TLS
provider](https://www.terraform.io/docs/providers/tls/r/private_key.html)). Additionally, this will deploy Tiller in a
way to be compatible with the [`grant`](https://github.com/gruntwork-io/kubergrunt/blob/master/README.md#grant) and
[`configure`](https://github.com/gruntwork-io/kubergrunt/blob/master/README.md#helm-configure) commands of `kubergrunt`
for setting up client access.

### Destroy

This Terraform module implements a resource that can declaratively define a Tiller install. Although this can not
implement a true `plan` of the underlying Kubernetes resources, this module can destroy a Tiller install if it is not
added.

The `helm` provider installs Tiller as part of the provider configuration and setup. This means that it will not
automatically be tracked in state, and thus will not be destroyed when the code is removed.


## Security Model of Tiller (the server component of Helm)

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

You can read more about the security model of Tiller in [their official docs](https://docs.helm.sh/using_helm/#securing-your-helm-installation).

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

### Service Account

Tiller relies on `ServiceAccounts` and the associated RBAC roles to properly restrict what Helm Charts can do. The RBAC
system in Kubernetes allows the operator to define fine grained permissions on what an individual or system can do in
the cluster. By using RBAC, you can restrict Tiller installs to only manage resources in particular namespaces, or even
restrict what resources Tiller can manage.

This module requires a `ServiceAccount` to use for Tiller, specified by the `service_account` input variable. The
roles for the `ServiceAccount` is managed outside of this module. See the [secure-helm example](/examples/secure-helm)
for example usage.

At a minimum, each Tiller server should be deployed in its own namespace separate from the namespace to manage
resources, and restricted to only be able to access those namespaces. This can be done by creating a `ServiceAccount`
limited to that namespace, with permissions granted to access the resource namespace:

```yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: dev-service-account
  namespace: dev-tiller
  labels:
    app: tiller
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1alpha1
metadata:
  namespace: dev-tiller
  name: dev-tiller-all
rules:
  - apiGroups: ["*"]
    resources: ["*"]
    verbs: ["*"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1alpha1
metadata:
  name: dev-role-dev-tiller-all-members
  namespace: dev-tiller
subjects:
  - kind: Group
    name: system:serviceaccounts:dev-service-account
roleRef:
  kind: Role
  name: dev-tiller-all
  apiGroup: "rbac.authorization.k8s.io"
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

This resource configuration creates a new `ServiceAccount` named `dev-service-account`. This resource then creates two
RBAC roles: one to grant admin permissions to the `dev` namespace (`dev-all`) and one to grant admin permissions to the
`dev-tiller` namespace (`dev-tiller-all`). Finally, the configuration specifies `RoleBinding` resources to bind the new
roles to the `ServiceAccount`.

### Namespaces: Tiller Namespace vs Resource Namespace

We recommend provisioning Tiller in its own namespace, separate from the namespace where the resources will ultimately
be deployed. The primary reason for doing this is so that you can lock down access to Tiller. Typically it is
challenging to implement RBAC controls to prevent access to specific resources within a `Namespace`, and still be
functional. For example, it is challenging to come up with rules to allow listing pods in a namespace while denying
access to a specific pod. This is because the `list` action in RBAC automatically pulls in the details included in a
`get` action, yet you can only limit access to specific resources on a `get` action in RBAC.

In practice, you will want to grant your users enough permissions in the resource namespace so that your users can
access the resources being deployed to perform their daily actions. This might include listing pods, setting up port
forwards to services, or even listing secrets in the namespace. If you share the namespace between where Tiller is
deployed and where the resources will be deployed, it is easy to accidentally set enough permissions to your users to be
able to access Tiller's resources. This includes the `ServiceAccount` credentials and the server side TLS certificates
that the Tiller pod uses.

This is why we recommend specifying a different namespace to deploy Tiller from where the resources are deployed.

Note: The exception to this is when you want to use `helm` to manage admin level resources (e.g deploying [the Kubernetes
Cluster Autoscaler](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler)). In this case, the Tiller
deployment will manage resources in the `kube-system` namespace, which is the admin level namespace of the cluster. For
this namespace, you will want your Tiller instance to also be in the `kube-system` namespace so that it shares all the
locked down access properties of that namespace.


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

As mentioned in the [Client Authentication section](#client-authentication), in order to grant access to a client, you
need to generate a new TLS certificate key pair that is signed by the CA installed on the Tiller server. This requires
access to the private key of the CA.

This module manages the TLS certificates through `kubergrunt`. As part of deploying Tiller, `kubergrunt` creates a
`Secret` in the `kube-system` namespace containing the private key and certificate of the CA used for deploying Tiller.
This can then be used by a cluster admin user to issue new key pairs that can be verified by the CA certificate
installed in the Tiller pod. This key pair can then be shared with the helm client to grant access.

At a high level, the process is:

- Download the CA key pair from Kubernetes.
- Issue a new TLS certificate key pair using the CA key pair.
- Upload the new TLS certificate key pair to a new Secret in a new Namespace that only the granted RBAC role has access
  to.
- Remove the local copies of the downloaded and generated certificates.
- The client then downloads the new TLS certificate key pair and configures the local helm client.

We provide a [subcommand in `kubergrunt`](https://github.com/gruntwork-io/kubergrunt/blob/master/README.md#helm-grant)
to automate this process, so that everything up to and including uploading the TLS certificates back to Kubernetes can
be done in one command:

```
kubergrunt helm grant --tiller-namespace NAMESPACE_OF_TILLER_TO_GRANT_ACCESS_TO --rbac-user USER_THAT_SHOULD_HAVE_ACCESS
```

This command will generate a new certificate key pair signed by the CA and upload it into a new `Secret` resource in the
namespace where Tiller is deployed. Then, this will grant the minimal set of permissions needed by the target RBAC user
to be able to download the certificate and access the Tiller pod endpoint.

We also provide a [subcommand in
`kubergrunt`](https://github.com/gruntwork-io/kubergrunt/blob/master/README.md#helm-configure) to automate the download
process for the helm client:

```
kubergrunt helm configure \
    --home-dir $HOME/.helm \
    --tiller-namespace NAMESPACE_OF_TILLER_TO_GRANT_ACCESS_TO \
    --rbac-user RBAC_USER_OF_AUTHENTICATION
```

<!--
-- This is not implemented yet

We also provide a subcommand to revoke access as well:

```
kubergrunt helm revoke --tiller-namespace NAMESPACE_OF_TILLER_TO_GRANT_ACCESS_TO --rbac-role ROLE_THAT_SHOULD_HAVE_ACCESS
```
-->
