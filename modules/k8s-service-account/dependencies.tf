# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DATA SOURCES
# These resources must already exist.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# KUBERNETES RESOURCE TEMPLATES FOR RBAC ROLE BINDINGS
# Render resource configs for RBAC role bindings.
# NOTE: These should be replaced with resources from the Terraform Kubernetes provider when they become available.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

data "template_file" "rbac_role_binding" {
  count    = "${length(var.rbac_roles)}"
  template = "${file("${path.module}/templates/rbac_role_binding.json")}"

  vars {
    namespace            = "${var.namespace}"
    service_account_name = "${var.name}"
    encoded_labels       = "${jsonencode(var.labels)}"
    encoded_annotations  = "${jsonencode(var.annotations)}"
    role_name            = "${element(var.rbac_roles, count.index)}"
  }
}

data "template_file" "rbac_role_binding_list" {
  template = "${file("${path.module}/templates/rbac_role_binding_list.json")}"

  vars {
    role_binding_jsons_rendered = "${join(",",data.template_file.rbac_role_binding.*.rendered)}"
  }
}
