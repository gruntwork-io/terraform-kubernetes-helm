package test

import (
	"fmt"
	"path/filepath"
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

func createExampleK8STillerTerraformOptions(
	t *testing.T,
	templatePath string,
	uniqueID string,
	testServiceAccountName string,
	testServiceAccountNamespace string,
) *terraform.Options {
	helmHome := filepath.Join(templatePath, ".helm")
	tillerNamespaceName := fmt.Sprintf("%s-tiller", strings.ToLower(uniqueID))
	resourceNamespaceName := fmt.Sprintf("%s-resources", strings.ToLower(uniqueID))
	tillerServiceAccountName := fmt.Sprintf("%s-tiller-service-account", strings.ToLower(uniqueID))
	encodedTestServiceAccount := fmt.Sprintf("%s/%s", testServiceAccountNamespace, testServiceAccountName)
	terraformVars := map[string]interface{}{
		"tiller_namespace":     tillerNamespaceName,
		"resource_namespace":   resourceNamespaceName,
		"service_account_name": tillerServiceAccountName,
		"tls_subject": map[string]string{
			"common_name": "tiller",
			"org":         "gruntwork",
		},
		"grant_access_to_rbac_service_accounts": []string{encodedTestServiceAccount},
		"helm_client_rbac_service_account":      encodedTestServiceAccount,
		"helm_home":                             helmHome,
	}
	terratestOptions := terraform.Options{
		TerraformDir: templatePath,
		Vars:         terraformVars,
	}
	return &terratestOptions
}
