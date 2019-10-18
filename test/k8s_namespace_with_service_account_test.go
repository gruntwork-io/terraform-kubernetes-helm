package test

import (
	"bytes"
	"encoding/json"
	"fmt"
	"path/filepath"
	"testing"
	"text/template"
	"time"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	authv1 "k8s.io/api/authorization/v1"
	corev1 "k8s.io/api/core/v1"
)

type TemplateArgs struct {
	Namespace          string
	ServiceAccountName string
}

func TestK8SNamespaceWithServiceAccountNoCreate(t *testing.T) {
	t.Parallel()

	// Uncomment any of the following to skip that section during the test
	// os.Setenv("SKIP_foo", "true") // This stage doesn't exist, but is useful in ensuring the test directory isn't copied
	// os.Setenv("SKIP_create_test_copy_of_examples", "true")
	// os.Setenv("SKIP_create_terratest_options", "true")
	// os.Setenv("SKIP_terraform_apply", "true")
	// os.Setenv("SKIP_validate", "true")
	// os.Setenv("SKIP_cleanup", "true")

	// Create a directory path that won't conflict
	workingDir := filepath.Join(".", "stages", t.Name())

	test_structure.RunTestStage(t, "create_test_copy_of_examples", func() {
		testFolder := test_structure.CopyTerraformFolderToTemp(t, "..", "examples")
		logger.Logf(t, "path to test folder %s\n", testFolder)
		k8sNamespaceTerraformModulePath := filepath.Join(testFolder, "k8s-namespace-with-service-account")
		test_structure.SaveString(t, workingDir, "k8sNamespaceTerraformModulePath", k8sNamespaceTerraformModulePath)
	})

	test_structure.RunTestStage(t, "create_terratest_options", func() {
		k8sNamespaceTerraformModulePath := test_structure.LoadString(t, workingDir, "k8sNamespaceTerraformModulePath")
		uniqueID := random.UniqueId()
		k8sNamespaceTerratestOptions := createExampleK8SNamespaceTerraformOptions(
			t, uniqueID, k8sNamespaceTerraformModulePath)
		k8sNamespaceTerratestOptions.Vars["create_resources"] = 0
		test_structure.SaveString(t, workingDir, "uniqueID", uniqueID)
		test_structure.SaveTerraformOptions(t, workingDir, k8sNamespaceTerratestOptions)
	})

	defer test_structure.RunTestStage(t, "cleanup", func() {
		k8sNamespaceTerratestOptions := test_structure.LoadTerraformOptions(t, workingDir)
		terraform.Destroy(t, k8sNamespaceTerratestOptions)
	})

	test_structure.RunTestStage(t, "terraform_apply", func() {
		k8sNamespaceTerratestOptions := test_structure.LoadTerraformOptions(t, workingDir)
		counts := terraform.GetResourceCount(t, terraform.InitAndPlan(t, k8sNamespaceTerratestOptions))
		assert.Equal(t, 0, counts.Change)
		assert.Equal(t, 0, counts.Destroy)
		// IMPORTANT NOTE: we don't expect any resources to create, but because of how the dependencies system works, we
		// expect to see 4 resources created: the 4 null_resources that act as a dependency getter.
		assert.Equal(t, 4, counts.Add)
	})
}

func TestK8SNamespaceWithServiceAccount(t *testing.T) {
	t.Parallel()

	// Uncomment any of the following to skip that section during the test
	// os.Setenv("SKIP_create_test_copy_of_examples", "true")
	// os.Setenv("SKIP_create_terratest_options", "true")
	// os.Setenv("SKIP_terraform_apply", "true")
	// os.Setenv("SKIP_validate", "true")
	// os.Setenv("SKIP_cleanup", "true")

	// Create a directory path that won't conflict
	workingDir := filepath.Join(".", "stages", t.Name())

	test_structure.RunTestStage(t, "create_test_copy_of_examples", func() {
		testFolder := test_structure.CopyTerraformFolderToTemp(t, "..", "examples")
		logger.Logf(t, "path to test folder %s\n", testFolder)
		k8sNamespaceTerraformModulePath := filepath.Join(testFolder, "k8s-namespace-with-service-account")
		test_structure.SaveString(t, workingDir, "k8sNamespaceTerraformModulePath", k8sNamespaceTerraformModulePath)
	})

	test_structure.RunTestStage(t, "create_terratest_options", func() {
		k8sNamespaceTerraformModulePath := test_structure.LoadString(t, workingDir, "k8sNamespaceTerraformModulePath")
		uniqueID := random.UniqueId()
		k8sNamespaceTerratestOptions := createExampleK8SNamespaceTerraformOptions(
			t, uniqueID, k8sNamespaceTerraformModulePath)
		test_structure.SaveString(t, workingDir, "uniqueID", uniqueID)
		test_structure.SaveTerraformOptions(t, workingDir, k8sNamespaceTerratestOptions)
	})

	defer test_structure.RunTestStage(t, "cleanup", func() {
		k8sNamespaceTerratestOptions := test_structure.LoadTerraformOptions(t, workingDir)
		terraform.Destroy(t, k8sNamespaceTerratestOptions)
	})

	test_structure.RunTestStage(t, "terraform_apply", func() {
		k8sNamespaceTerratestOptions := test_structure.LoadTerraformOptions(t, workingDir)
		terraform.InitAndApply(t, k8sNamespaceTerratestOptions)
	})

	test_structure.RunTestStage(t, "validate", func() {
		k8sNamespaceTerratestOptions := test_structure.LoadTerraformOptions(t, workingDir)
		// Spawn a grouped test that is not marked as parallel, so that we will wait for all the parallel subtests to
		// finish, so that we can clean up after all the tests are done.
		t.Run("group", func(t *testing.T) {
			t.Run("ValidateNamespaceTest", func(t *testing.T) {
				t.Parallel()
				validateNamespace(t, k8sNamespaceTerratestOptions)
			})
			t.Run("ValidateRbacAccessAllTest", func(t *testing.T) {
				t.Parallel()
				validateRbacAccessAll(t, k8sNamespaceTerratestOptions)
			})
			t.Run("ValidateRbacAccessReadOnlyTest", func(t *testing.T) {
				t.Parallel()
				validateRbacAccessReadOnly(t, k8sNamespaceTerratestOptions)
			})
		})
	})
}

// validateNamespace verifies that the namespace was created and is active.
func validateNamespace(t *testing.T, k8sNamespaceTerratestOptions *terraform.Options) {
	namespace := terraform.Output(t, k8sNamespaceTerratestOptions, "name")
	kubectlOptions := k8s.NewKubectlOptions("", "", "")
	k8sNamespace := k8s.GetNamespace(t, kubectlOptions, namespace)
	assert.Equal(t, k8sNamespace.Name, namespace)
	assert.Equal(t, k8sNamespace.Status.Phase, corev1.NamespaceActive)
}

// validateRbacAccessAll verifies that the access all RBAC role has read and write privileges to the namespace
func validateRbacAccessAll(t *testing.T, k8sNamespaceTerratestOptions *terraform.Options) {
	kubectlOptions := k8s.NewKubectlOptions("", "", "")
	namespace := terraform.Output(t, k8sNamespaceTerratestOptions, "name")
	serviceAccountName := terraform.Output(t, k8sNamespaceTerratestOptions, "service_account_access_all")
	templateArgs := TemplateArgs{
		Namespace:          namespace,
		ServiceAccountName: serviceAccountName,
	}
	defaultNamespaceTemplateArgs := TemplateArgs{
		Namespace: "default",
	}
	checkCreatePod := RenderTemplateAsString(t, "./kubefixtures/namespace-check-create-pod.json.tpl", templateArgs)
	checkListPod := RenderTemplateAsString(t, "./kubefixtures/namespace-check-list-pod.json.tpl", templateArgs)
	checkDefaultCreatePod := RenderTemplateAsString(t, "./kubefixtures/namespace-check-create-pod.json.tpl", defaultNamespaceTemplateArgs)
	checkDefaultListPod := RenderTemplateAsString(t, "./kubefixtures/namespace-check-list-pod.json.tpl", defaultNamespaceTemplateArgs)

	// Verify read write access to the targeted namespace using auth can-i API, but not to the default namespace
	checkAccessForServiceAccount(
		t,
		kubectlOptions,
		namespace,
		serviceAccountName,
		func(t *testing.T, namespacedKubectlOptions *k8s.KubectlOptions, curlPodName string) {
			assert.True(t, canAccess(t, namespacedKubectlOptions, curlPodName, checkCreatePod))
			assert.True(t, canAccess(t, namespacedKubectlOptions, curlPodName, checkListPod))
			assert.False(t, canAccess(t, namespacedKubectlOptions, curlPodName, checkDefaultCreatePod))
			assert.False(t, canAccess(t, namespacedKubectlOptions, curlPodName, checkDefaultListPod))
		},
	)
}

// validateRbacAccessReadOnly verifies that the access read only RBAC role has read only privileges to the namespace
func validateRbacAccessReadOnly(t *testing.T, k8sNamespaceTerratestOptions *terraform.Options) {
	kubectlOptions := k8s.NewKubectlOptions("", "", "")
	namespace := terraform.Output(t, k8sNamespaceTerratestOptions, "name")
	serviceAccountName := terraform.Output(t, k8sNamespaceTerratestOptions, "service_account_access_read_only")
	templateArgs := TemplateArgs{
		Namespace:          namespace,
		ServiceAccountName: serviceAccountName,
	}
	defaultNamespaceTemplateArgs := TemplateArgs{
		Namespace: "default",
	}
	checkCreatePod := RenderTemplateAsString(t, "./kubefixtures/namespace-check-create-pod.json.tpl", templateArgs)
	checkListPod := RenderTemplateAsString(t, "./kubefixtures/namespace-check-list-pod.json.tpl", templateArgs)
	checkDefaultCreatePod := RenderTemplateAsString(t, "./kubefixtures/namespace-check-create-pod.json.tpl", defaultNamespaceTemplateArgs)
	checkDefaultListPod := RenderTemplateAsString(t, "./kubefixtures/namespace-check-list-pod.json.tpl", defaultNamespaceTemplateArgs)

	// Verify read only access to the targeted namespace using auth can-i API, but not to the default namespace
	checkAccessForServiceAccount(
		t,
		kubectlOptions,
		namespace,
		serviceAccountName,
		func(t *testing.T, namespacedKubectlOptions *k8s.KubectlOptions, curlPodName string) {
			// Verify read write access to the targeted namespace using auth can-i API, but not to the default namespace
			assert.False(t, canAccess(t, namespacedKubectlOptions, curlPodName, checkCreatePod))
			assert.True(t, canAccess(t, namespacedKubectlOptions, curlPodName, checkListPod))
			assert.False(t, canAccess(t, namespacedKubectlOptions, curlPodName, checkDefaultCreatePod))
			assert.False(t, canAccess(t, namespacedKubectlOptions, curlPodName, checkDefaultListPod))
		},
	)
}

// checkAccessForServiceAccount checks accessibility of the assumed service account by making a request as the service
// account in a curl Pod that was launched with the service account.
func checkAccessForServiceAccount(
	t *testing.T,
	kubectlOptions *k8s.KubectlOptions,
	namespace string,
	serviceAccountName string,
	accessCheckFunc func(*testing.T, *k8s.KubectlOptions, string),
) {
	// Create the Pod that can be used to access the kubernetes API as the service account
	// This Pod includes a container that can be used to run curl, and a proxy server to the kubernetes API. By binding
	// a ServiceAccount to the proxy, curl requests made to the kubernetes API from the curl container will be made by
	// assuming the ServiceAccount credentials. This way, you can verify permissions associated with the Service
	// Account.
	templateArgs := TemplateArgs{Namespace: namespace, ServiceAccountName: serviceAccountName}
	curlKubeapiResourceConfig := RenderTemplateAsString(t, "./kubefixtures/curl-kubeapi-as-service-account.yml.tpl", templateArgs)
	defer k8s.KubectlDeleteFromString(t, kubectlOptions, curlKubeapiResourceConfig)
	k8s.KubectlApplyFromString(t, kubectlOptions, curlKubeapiResourceConfig)
	curlPodName := fmt.Sprintf("%s-curl", serviceAccountName)
	// Wait for up to 5 minutes for pod to start (60 tries, 5 seconds inbetween each trial)
	// We explicitly set the namespace to default here, because the Kubernetes API requires an explicit namespace when
	// looking up pods by name.
	namespacedKubectlOptions := k8s.NewKubectlOptions("", "", namespace)
	k8s.WaitUntilPodAvailable(t, namespacedKubectlOptions, curlPodName, 60, 5*time.Second)

	// Run the check function while the curl pod is up
	accessCheckFunc(t, namespacedKubectlOptions, curlPodName)
}

// canAccess checks if the ServiceAccount of the curl pod can perform the action described in the json data.
func canAccess(t *testing.T, kubectlOptions *k8s.KubectlOptions, curlPodName string, actionJsonData string) bool {
	rawCheckResult, err := k8s.RunKubectlAndGetOutputE(
		t,
		kubectlOptions,
		"exec",
		"-i",
		curlPodName,
		"-c",
		"main",
		"--",
		// The rest of the args are the command to run in the container
		"curl",
		"-s",
		"-X",
		"POST",
		"-H",
		"Content-type: application/json",
		"-d",
		actionJsonData,
		"localhost:8001/apis/authorization.k8s.io/v1/selfsubjectaccessreviews",
	)
	require.NoError(t, err)
	var checkResult authv1.SelfSubjectAccessReview
	require.NoError(t, json.Unmarshal([]byte(rawCheckResult), &checkResult))
	return checkResult.Status.Allowed
}

// RenderTemplateAsString renders the given golang template located at the fpath with the provided data into a string.
func RenderTemplateAsString(t *testing.T, fpath string, data interface{}) string {
	namespaceServiceAccountTemplate, err := template.ParseFiles(fpath)
	require.NoError(t, err)
	buf := bytes.NewBufferString("")
	require.NoError(t, namespaceServiceAccountTemplate.Execute(buf, data))
	return buf.String()
}
