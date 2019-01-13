# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DATA SOURCES
# These resources must already exist.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# KUBERNETES RESOURCE TEMPLATES FOR RBAC ROLES
# Render resource configs for RBAC roles.
# NOTE: These should be replaced with resources from the Terraform Kubernetes provider when they become available.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

data "template_file" "rbac_role_access_all" {
  template = "${file("${path.module}/templates/rbac_role_access_all.json")}"

  vars {
    namespace = "${var.name}"
  }
}

data "template_file" "rbac_role_access_read_only" {
  template = "${file("${path.module}/templates/rbac_role_access_read_only.json")}"

  vars {
    namespace = "${var.name}"
  }
}
