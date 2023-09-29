# Kubernetes Cluster Agnostic Automated Testing Configuration
This documentation will describe how to configure automated tests across multiple kubernetes clusters to run during Jenkins builds.
Since each cluster may require some unique configurations, we have provided methods to override specific values per cluster.

## Jenkins Parameters
The following Jenkins parameters are used during the Application Testing stages.
Parameters will be defined in the Jenkinsfile, but some values can be overridden using Jenkins environment variables. 
Override functionality was implemented to support using the same Jenkinsfile across multiple environments and git branches.
* __chartRepository__: Git config repository that contains your Helm chart and value YAML files.
* __chartBranch__: Git config repository branch to obtain Helm chart from.
  * This value can be overridden by adding a Jenkins environment variable called `chartBranch`.
* __chartPath__: Path to the chart directory within the `chartRepository`.
* __configPath__: Path to the config directory within the `chartRepository`.
  * When a config path is defined, the chart value YAML files located at the specified path within the `chartBranch` of `chartRepository` will be used.
  * When a config path is not defined, the chart value YAML files located within the service repo will be used.
* __chartValueFunctionalTestFile__: Value YAML file used to configure the Helm deployments used for functional testing.
* __chartValuePerformanceTestFile__: Value YAML file used to configure the Helm deployments used for performance testing.
* __chartValueReviewInstanceFile__: Value YAML file used to configure the Helm deployments used for the Deploy Review Instance stage.
* __cucumberOpts__: Cucumber options to use during Functional Testing stage.
  * Use this parameter to define which tests to run using tags.
    For example, `cucumberOpts = "--tags @DEV"` will only run tests with the *@DEV* tag.
  * This value can be overridden by adding a Jenkins environment variable called `cucumberOpts`.

### Jenkins Environment Variables and Parameter Overrides
We have implemented the ability to override the `chartBranch` and `cucumberOpts` Jenkinsfile parameters with Jenkins environment variables since these values may need to be unique for different environments.
Using overrides makes the Jenkinsfile easier to maintain across multiple branches since the same Jenkinsfile can now be used for multiple environments.

Supported Jenkins environment variables include:
* __chartBranch__: Overrides `chartBranch` Jenkins parameter described above.
* __cucumberOpts__: Overrides `cucubmerOpts` Jenkins parameter described above.
* __MAVEN_REPOSITORY_URL__: Url of nexus repository to pull maven dependencies from. Defaults to https://nexus.dev.bip.va.gov/repository if null.
* __DOCKER_REGISTRY_URL__: Url of Docker repository where built Docker image is pushed to.
This variable will likely be set on the Docker Kubernetes Pod template after intake by default.
Defaults to https://nexus.dev.bip.va.gov:5000 if null.

See [Overriding Jenkins Environment Variables](../README.md#overriding-jenkins-environment-variables)

## Deployment Config YAMLs
The Functional Test, Performance Test, and Deploy Review Instance Jenkins pipeline stages will deploy ephemeral Kubernetes Pods.
The deployment config values files are specified by the `chartValueFunctionalTestFile`, `chartValuePerformanceTestFile`, and `chartValueReviewInstanceFile` Jenkins parameters.
By default, the Jenkins pipeline will pull the specified values files from the service repository.
This behavior can be overridden using the `chartPath` Jenkins parameter described below.

### Deployment Config YAML Overrides
We have implemented the ability to define different deployment config value YAML files for each environment within the config repository.
Use `chartPath` to define the path to the directory where the value YAMLs are located within the config repository.
These value files will be pulled from the `chartPath` within the `chartBranch` of your `chartRepository`.

See [Overriding Deployment Config YAMLs](https://github.com/department-of-veterans-affairs/bip-jenkins-lib/blob/development/docs/deploy-review-instance.md#overriding-deployment-config-yamls) documentation for implementation instructions.

Example using `testing-config` as the `chartPath`:

<img src = "images/testing-config-example.jpg">

## Diagram
Below is a simple diagram showing where the configurations described within this document should be defined:

<img src = "images/cluster-agnostic-build-diagram.jpg">