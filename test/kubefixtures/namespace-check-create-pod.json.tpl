{
    "apiVersion": "authorization.k8s.io/v1",
    "kind": "SelfSubjectAccessReview",
    "spec": {
        "resourceAttributes": {
            "namespace": "{{ .Namespace }}",
            "verb": "create",
            "group": "core",
            "resource": "pod"
        }
    }
}
