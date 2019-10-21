package test

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/shell"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/require"
)

func TestK8STillerKubergrunt(t *testing.T) {
	t.Parallel()

	// Uncomment any of the following to skip that section during the test
	// os.Setenv("SKIP_create_test_copy_of_examples", "true")
	// os.Setenv("SKIP_create_test_service_account", "true")
	// os.Setenv("SKIP_create_terratest_options", "true")
	// os.Setenv("SKIP_terraform_apply", "true")
	// os.Setenv("SKIP_validate", "true")
	// os.Setenv("SKIP_validate_upgrade", "true")
	// os.Setenv("SKIP_cleanup", "true")

	// Create a directory path that won't conflict
	workingDir := filepath.Join(".", "stages", t.Name())

	test_structure.RunTestStage(t, "create_test_copy_of_examples", func() {
		k8sTillerTerraformModulePath := test_structure.CopyTerraformFolderToTemp(t, "..", "examples/k8s-tiller-kubergrunt-minikube")
		logger.Logf(t, "path to test folder %s\n", k8sTillerTerraformModulePath)
		helmHome := filepath.Join(k8sTillerTerraformModulePath, ".helm")
		// make sure to create the helm home directory
		require.NoError(t, os.Mkdir(helmHome, 0700))

		test_structure.SaveString(t, workingDir, "k8sTillerTerraformModulePath", k8sTillerTerraformModulePath)
		test_structure.SaveString(t, workingDir, "helmHome", helmHome)
	})

	// Create a ServiceAccount in its own namespace that we can use to login as for testing purposes.
	test_structure.RunTestStage(t, "create_test_service_account", func() {
		uniqueID := random.UniqueId()
		testServiceAccountName := fmt.Sprintf("%s-test-account", strings.ToLower(uniqueID))
		testServiceAccountNamespace := fmt.Sprintf("%s-test-account-namespace", strings.ToLower(uniqueID))
		tmpConfigPath := k8s.CopyHomeKubeConfigToTemp(t)
		kubectlOptions := k8s.NewKubectlOptions("", tmpConfigPath, "")

		k8s.CreateNamespace(t, kubectlOptions, testServiceAccountNamespace)
		kubectlOptions.Namespace = testServiceAccountNamespace
		k8s.CreateServiceAccount(t, kubectlOptions, testServiceAccountName)
		token := k8s.GetServiceAccountAuthToken(t, kubectlOptions, testServiceAccountName)
		err := k8s.AddConfigContextForServiceAccountE(t, kubectlOptions, testServiceAccountName, testServiceAccountName, token)
		// We do the error check and namespace deletion manually here, because we can't defer it within the test stage.
		if err != nil {
			k8s.DeleteNamespace(t, kubectlOptions, testServiceAccountNamespace)
			t.Fatal(err)
		}

		test_structure.SaveString(t, workingDir, "uniqueID", uniqueID)
		test_structure.SaveString(t, workingDir, "tmpKubectlConfigPath", tmpConfigPath)
		test_structure.SaveString(t, workingDir, "testServiceAccountName", testServiceAccountName)
		test_structure.SaveString(t, workingDir, "testServiceAccountNamespace", testServiceAccountNamespace)
	})

	test_structure.RunTestStage(t, "create_terratest_options", func() {
		uniqueID := test_structure.LoadString(t, workingDir, "uniqueID")
		helmHome := test_structure.LoadString(t, workingDir, "helmHome")
		testServiceAccountName := test_structure.LoadString(t, workingDir, "testServiceAccountName")
		testServiceAccountNamespace := test_structure.LoadString(t, workingDir, "testServiceAccountNamespace")
		k8sTillerTerraformModulePath := test_structure.LoadString(t, workingDir, "k8sTillerTerraformModulePath")

		k8sTillerTerratestOptions := createExampleK8STillerKubergruntTerraformOptions(t, k8sTillerTerraformModulePath, helmHome, uniqueID, testServiceAccountName, testServiceAccountNamespace)

		test_structure.SaveTerraformOptions(t, workingDir, k8sTillerTerratestOptions)
	})

	defer test_structure.RunTestStage(t, "cleanup", func() {
		k8sTillerTerratestOptions := test_structure.LoadTerraformOptions(t, workingDir)
		terraform.Destroy(t, k8sTillerTerratestOptions)

		testServiceAccountNamespace := test_structure.LoadString(t, workingDir, "testServiceAccountNamespace")
		kubectlOptions := k8s.NewKubectlOptions("", "", "")
		k8s.DeleteNamespace(t, kubectlOptions, testServiceAccountNamespace)
	})

	test_structure.RunTestStage(t, "terraform_apply", func() {
		k8sTillerTerratestOptions := test_structure.LoadTerraformOptions(t, workingDir)
		terraform.InitAndApply(t, k8sTillerTerratestOptions)
	})

	test_structure.RunTestStage(t, "validate", func() {
		helmHome := test_structure.LoadString(t, workingDir, "helmHome")
		k8sTillerTerratestOptions := test_structure.LoadTerraformOptions(t, workingDir)
		resourceNamespace := k8sTillerTerratestOptions.Vars["resource_namespace"].(string)
		tmpConfigPath := test_structure.LoadString(t, workingDir, "tmpKubectlConfigPath")
		testServiceAccountName := test_structure.LoadString(t, workingDir, "testServiceAccountName")
		kubectlOptions := k8s.NewKubectlOptions(testServiceAccountName, tmpConfigPath, resourceNamespace)

		runHelm(
			t,
			kubectlOptions,
			helmHome,
			"install",
			"stable/kubernetes-dashboard",
			"--wait",
		)
	})

	test_structure.RunTestStage(t, "validate_upgrade", func() {
		// Make sure the upgrade command mentioned in the docs actually works
		helmHome := test_structure.LoadString(t, workingDir, "helmHome")
		tmpConfigPath := test_structure.LoadString(t, workingDir, "tmpKubectlConfigPath")
		kubectlOptions := k8s.NewKubectlOptions("", tmpConfigPath, "")

		runHelm(
			t,
			kubectlOptions,
			helmHome,
			"init",
			"--upgrade",
			"--wait",
		)
	})
}

func runHelm(t *testing.T, options *k8s.KubectlOptions, helmHome string, args ...string) {
	helmArgs := []string{"helm"}
	if options.ContextName != "" {
		helmArgs = append(helmArgs, "--kube-context", options.ContextName)
	}
	if options.ConfigPath != "" {
		helmArgs = append(helmArgs, "--kubeconfig", options.ConfigPath)
	}
	if options.Namespace != "" {
		helmArgs = append(helmArgs, "--namespace", options.Namespace)
	}
	helmArgs = append(helmArgs, args...)
	helmCmd := strings.Join(helmArgs, " ")

	// TODO: make this test platform independent
	helmEnvPath := filepath.Join(helmHome, "env")
	cmd := shell.Command{
		Command: "sh",
		Args: []string{
			"-c",
			fmt.Sprintf(". %s && %s", helmEnvPath, helmCmd),
		},
	}
	shell.RunCommand(t, cmd)
}
