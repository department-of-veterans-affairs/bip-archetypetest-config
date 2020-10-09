# Deployment Configuration
Deployments on the BIP platform are done using [Flux](https://github.com/weaveworks/flux) and [Helm](https://helm.sh). Flux is configured to monitor this Git repository for changes. When changes are detected, Flux will read the Kubernetes YAML files in the configured repository location and apply them to the Kubernetes cluster.

## Directory Structure
Each namespace used by your project has its own instances of Flux and Helm that is monitoring a specific folder within this repository. Instances are configured to look at `deployment-config/{cluster}`. For example the `Dev` cluster looks at `deployment-config/dev`. Within that folder, the instances will only apply objects targetted for their namespace.

## Helm Integration
If you are deploying a Helm Chart, then you should create a `HelmRelease` object YAML that describes the chart you want to apply and the configuration of that chart. The bip-archetypetest application provides an [example of a HelmRelease object](dev/bip-archetypetest-dev.yaml). Flux will apply this object to your namespace, which in turn will be read by the [Flux Helm operator](https://github.com/weaveworks/flux/blob/master/site/helm-integration.md) and it will then install the chart using Helm. For more information on writing your `HelmRelease` object YAML, see the [Flux Helm operator documentation](https://github.com/weaveworks/flux/blob/master/site/helm-integration.md).

## Health Check Vars
Due to 500 errors occurring when Vault and Consul are down, health checks have been disabled by default for both in the deployment configs using the following vars:
* `management.health.consul.enabled=false`
    * Disables default Consul health checks. 
    More info [here](https://cloud.spring.io/spring-cloud-consul/multi/multi_spring-cloud-consul-discovery.html#_http_health_check).
* `spring.cloud.discovery.client.composite-indicator.enabled=false`
    * Disables default Discovery Client composite Health Indicator. 
    More info [here](https://spring.getdocs.org/en-US/spring-cloud-docs/spring-cloud-commons/cloud-native-applications/spring-cloud-commons:-common-abstractions/discovery-client.html#_health_indicator).
* `management.health.vault.enabled=false`
    * Disables default Vault health checks.
    More info [here](https://cloud.spring.io/spring-cloud-vault/reference/html/).

These health checks can be enabled or disabled by updating the corresponding values in the desired deployment-config.
To validate these values have been updated appropriately check the `actuator/env` endpoint.
To validate the health checks are disabled/enabled as desired check the `actuator/health` endpoint.
