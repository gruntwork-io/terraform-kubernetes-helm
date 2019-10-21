package test

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/shell"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/require"
)

// This test makes sure the root example can run without errors on a machine without kubergrunt
func TestK8STillerNoKubergrunt(t *testing.T) {
	t.Parallel()

	if kubergruntInstalled(t) {
		t.Skip("This test assumes kubergrunt is not installed.")
	}

	// os.Setenv("SKIP_create_test_copy_of_examples", "true")
	// os.Setenv("SKIP_create_test_service_account", "true")
	// os.Setenv("SKIP_create_terratest_options", "true")
	// os.Setenv("SKIP_terraform_apply", "true")
	// os.Setenv("SKIP_cleanup", "true")

	// Create a directory path that won't conflict
	workingDir := filepath.Join(".", "stages", t.Name())

	test_structure.RunTestStage(t, "create_test_copy_of_examples", func() {
		uniqueID := random.UniqueId()
		k8sTillerTerraformModulePath := test_structure.CopyTerraformFolderToTemp(t, "..", ".")
		logger.Logf(t, "path to test folder %s\n", k8sTillerTerraformModulePath)
		helmHome := filepath.Join(k8sTillerTerraformModulePath, ".helm")
		// make sure to create the helm home directory
		require.NoError(t, os.Mkdir(helmHome, 0700))

		test_structure.SaveString(t, workingDir, "k8sTillerTerraformModulePath", k8sTillerTerraformModulePath)
		test_structure.SaveString(t, workingDir, "helmHome", helmHome)
		test_structure.SaveString(t, workingDir, "uniqueID", uniqueID)
	})

	test_structure.RunTestStage(t, "create_terratest_options", func() {
		uniqueID := test_structure.LoadString(t, workingDir, "uniqueID")
		helmHome := test_structure.LoadString(t, workingDir, "helmHome")
		k8sTillerTerraformModulePath := test_structure.LoadString(t, workingDir, "k8sTillerTerraformModulePath")

		k8sTillerTerratestOptions := createExampleK8STillerTerraformOptions(t, k8sTillerTerraformModulePath, helmHome, uniqueID)

		test_structure.SaveTerraformOptions(t, workingDir, k8sTillerTerratestOptions)
	})

	defer test_structure.RunTestStage(t, "cleanup", func() {
		k8sTillerTerratestOptions := test_structure.LoadTerraformOptions(t, workingDir)
		terraform.Destroy(t, k8sTillerTerratestOptions)
	})

	test_structure.RunTestStage(t, "terraform_apply", func() {
		k8sTillerTerratestOptions := test_structure.LoadTerraformOptions(t, workingDir)
		terraform.InitAndApply(t, k8sTillerTerratestOptions)
	})
}

func TestK8STiller(t *testing.T) {
	t.Parallel()

	// Uncomment any of the following to skip that section during the test
	// os.Setenv("SKIP_create_test_copy_of_examples", "true")
	// os.Setenv("SKIP_create_test_service_account", "true")
	// os.Setenv("SKIP_create_terratest_options", "true")
	// os.Setenv("SKIP_terraform_apply", "true")
	// os.Setenv("SKIP_setup_helm_client", "true")
	// os.Setenv("SKIP_validate", "true")
	// os.Setenv("SKIP_cleanup", "true")

	// Create a directory path that won't conflict
	workingDir := filepath.Join(".", "stages", t.Name())

	test_structure.RunTestStage(t, "create_test_copy_of_examples", func() {
		uniqueID := random.UniqueId()
		k8sTillerTerraformModulePath := test_structure.CopyTerraformFolderToTemp(t, "..", ".")
		logger.Logf(t, "path to test folder %s\n", k8sTillerTerraformModulePath)
		helmHome := filepath.Join(k8sTillerTerraformModulePath, ".helm")
		// make sure to create the helm home directory
		require.NoError(t, os.Mkdir(helmHome, 0700))

		test_structure.SaveString(t, workingDir, "k8sTillerTerraformModulePath", k8sTillerTerraformModulePath)
		test_structure.SaveString(t, workingDir, "helmHome", helmHome)
		test_structure.SaveString(t, workingDir, "uniqueID", uniqueID)
	})

	test_structure.RunTestStage(t, "create_terratest_options", func() {
		uniqueID := test_structure.LoadString(t, workingDir, "uniqueID")
		helmHome := test_structure.LoadString(t, workingDir, "helmHome")
		k8sTillerTerraformModulePath := test_structure.LoadString(t, workingDir, "k8sTillerTerraformModulePath")

		k8sTillerTerratestOptions := createExampleK8STillerTerraformOptions(t, k8sTillerTerraformModulePath, helmHome, uniqueID)

		test_structure.SaveTerraformOptions(t, workingDir, k8sTillerTerratestOptions)
	})

	defer test_structure.RunTestStage(t, "cleanup", func() {
		k8sTillerTerratestOptions := test_structure.LoadTerraformOptions(t, workingDir)
		terraform.Destroy(t, k8sTillerTerratestOptions)
	})

	test_structure.RunTestStage(t, "terraform_apply", func() {
		k8sTillerTerratestOptions := test_structure.LoadTerraformOptions(t, workingDir)
		terraform.InitAndApply(t, k8sTillerTerratestOptions)
	})

	test_structure.RunTestStage(t, "setup_helm_client", func() {
		helmHome := test_structure.LoadString(t, workingDir, "helmHome")
		kubectlOptions := k8s.NewKubectlOptions("", "", "")
		k8sTillerTerratestOptions := test_structure.LoadTerraformOptions(t, workingDir)
		tillerNamespace := terraform.OutputRequired(t, k8sTillerTerratestOptions, "tiller_namespace")
		resourceNamespace := terraform.OutputRequired(t, k8sTillerTerratestOptions, "resource_namespace")
		tillerVersion := k8sTillerTerratestOptions.Vars["tiller_version"].(string)

		runKubergruntWait(t, kubectlOptions, tillerNamespace, tillerVersion)
		runKubergruntConfigure(t, kubectlOptions, helmHome, tillerNamespace, resourceNamespace)
	})

	test_structure.RunTestStage(t, "validate", func() {
		helmHome := test_structure.LoadString(t, workingDir, "helmHome")
		k8sTillerTerratestOptions := test_structure.LoadTerraformOptions(t, workingDir)
		resourceNamespace := terraform.OutputRequired(t, k8sTillerTerratestOptions, "resource_namespace")
		kubectlOptions := k8s.NewKubectlOptions("", "", resourceNamespace)

		runHelm(
			t,
			kubectlOptions,
			helmHome,
			"install",
			"stable/kubernetes-dashboard",
			"--wait",
		)
	})
}

func runKubergruntConfigure(
	t *testing.T,
	options *k8s.KubectlOptions,
	helmHome string,
	tillerNamespace string,
	resourceNamespace string,
) {
	kubergruntArgs := []string{
		"helm",
		"configure",
		"--helm-home", helmHome,
		"--tiller-namespace", tillerNamespace,
		"--resource-namespace", resourceNamespace,
		"--rbac-user", "minikube",
	}
	if options.ContextName != "" {
		kubergruntArgs = append(kubergruntArgs, "--kubectl-context-name", options.ContextName)
	}
	if options.ConfigPath != "" {
		kubergruntArgs = append(kubergruntArgs, "--kubeconfig", options.ConfigPath)
	}

	cmd := shell.Command{
		Command: "kubergrunt",
		Args:    kubergruntArgs,
	}
	shell.RunCommand(t, cmd)
}

func runKubergruntWait(
	t *testing.T,
	options *k8s.KubectlOptions,
	tillerNamespace string,
	tillerVersion string,
) {
	kubergruntArgs := []string{
		"helm",
		"wait-for-tiller",
		"--tiller-namespace", tillerNamespace,
		"--expected-tiller-version", tillerVersion,
	}
	if options.ContextName != "" {
		kubergruntArgs = append(kubergruntArgs, "--kubectl-context-name", options.ContextName)
	}
	if options.ConfigPath != "" {
		kubergruntArgs = append(kubergruntArgs, "--kubeconfig", options.ConfigPath)
	}

	cmd := shell.Command{
		Command: "kubergrunt",
		Args:    kubergruntArgs,
	}
	shell.RunCommand(t, cmd)
}

func kubergruntInstalled(t *testing.T) bool {
	cmd := shell.Command{
		Command: "kubergrunt",
		Args:    []string{"version"},
	}
	err := shell.RunCommandE(t, cmd)
	return err == nil

}
