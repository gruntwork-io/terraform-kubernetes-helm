{
    "apiVersion": "authorization.k8s.io/v1",
    "kind": "SelfSubjectAccessReview",
    "spec": {
        "resourceAttributes": {
            "namespace": "{{ .Namespace }}",
            "verb": "list",
            "group": "core",
            "resource": "pod"
        }
    }
}
