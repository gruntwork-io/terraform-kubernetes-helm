package test

import (
	"fmt"
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

func createExampleK8STillerKubergruntTerraformOptions(
	t *testing.T,
	templatePath string,
	helmHome string,
	uniqueID string,
	testServiceAccountName string,
	testServiceAccountNamespace string,
) *terraform.Options {
	tillerNamespaceName := fmt.Sprintf("%s-tiller", strings.ToLower(uniqueID))
	resourceNamespaceName := fmt.Sprintf("%s-resources", strings.ToLower(uniqueID))
	tillerServiceAccountName := fmt.Sprintf("%s-tiller-service-account", strings.ToLower(uniqueID))
	encodedTestServiceAccount := fmt.Sprintf("%s/%s", testServiceAccountNamespace, testServiceAccountName)
	terraformVars := map[string]interface{}{
		"tiller_version":       "v2.12.2",
		"tiller_namespace":     tillerNamespaceName,
		"resource_namespace":   resourceNamespaceName,
		"service_account_name": tillerServiceAccountName,
		"tls_subject": map[string]string{
			"common_name": "tiller",
			"org":         "Gruntwork",
		},
		"client_tls_subject": map[string]string{
			"common_name": encodedTestServiceAccount,
			"org":         "Gruntwork",
		},
		"helm_client_rbac_service_account": encodedTestServiceAccount,
		"helm_home":                        helmHome,
	}
	terratestOptions := terraform.Options{
		TerraformDir: templatePath,
		Vars:         terraformVars,
	}
	return &terratestOptions
}

func createExampleK8STillerTerraformOptions(
	t *testing.T,
	templatePath string,
	helmHome string,
	uniqueID string,
) *terraform.Options {
	tillerNamespaceName := fmt.Sprintf("%s-tiller", strings.ToLower(uniqueID))
	resourceNamespaceName := fmt.Sprintf("%s-resources", strings.ToLower(uniqueID))
	tillerServiceAccountName := fmt.Sprintf("%s-tiller-service-account", strings.ToLower(uniqueID))
	terraformVars := map[string]interface{}{
		"tiller_version":       "v2.12.2",
		"tiller_namespace":     tillerNamespaceName,
		"resource_namespace":   resourceNamespaceName,
		"service_account_name": tillerServiceAccountName,
		"tls_subject": map[string]string{
			"common_name":  "tiller",
			"organization": "Gruntwork",
		},
		"client_tls_subject": map[string]string{
			"common_name":  "minikube",
			"organization": "Gruntwork",
		},
		"grant_helm_client_rbac_user": "minikube",
	}
	terratestOptions := terraform.Options{
		TerraformDir: templatePath,
		Vars:         terraformVars,
	}
	return &terratestOptions
}
