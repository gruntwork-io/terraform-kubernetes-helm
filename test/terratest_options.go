package test

import (
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

func createExampleK8SNamespaceTerraformOptions(t *testing.T, uniqueID string, templatePath string) *terraform.Options {
	terraformVars := map[string]interface{}{"name": strings.ToLower(uniqueID)}
	terratestOptions := terraform.Options{
		TerraformDir: templatePath,
		Vars:         terraformVars,
	}
	return &terratestOptions
}
