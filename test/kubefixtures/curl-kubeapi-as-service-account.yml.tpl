---
# A Pod that can be used to curl kuberenetes api as the service account
# This works by having a sidecar container provide an kubectl API proxy that uses the service account token to talk to
# the real Kubernetes API in the cluster, and access it via the main curl container.
# Source: "Kubernetes in Action", section 12.1.4
apiVersion: v1
kind: Pod
metadata:
  name: {{ .ServiceAccountName }}-curl
  namespace: {{ .Namespace }}
spec:
  serviceAccountName: {{ .ServiceAccountName }}
  containers:
  - name: main
    image: tutum/curl
    # This is intentional. Because of the way pods work, the container needs to be up and running as a service in order
    # to run arbitrary commands. Therewore, we use a sleep here to create a pseudo service container that houses the
    # curl binary that we can then drop into and use via `kubectl exec`.
    command: ["sleep", "9999999"]
  - name: ambassador
    image: luksa/kubectl-proxy
