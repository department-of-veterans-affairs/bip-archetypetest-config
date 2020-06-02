# Deployment Configuration
Deployments on the BIP platform are done using [Flux](https://github.com/weaveworks/flux) and [Helm](https://helm.sh). Flux is configured to monitor this Git repository for changes. When changes are detected, Flux will read the Kubernetes YAML files in the configured repository location and apply them to the Kubernetes cluster.

## Directory Structure
Each namespace used by your project has its own instances of Flux and Helm that is monitoring a specific folder within this repository. Instances are configured to look at `deployment-config/{cluster}`. For example the `Dev` cluster looks at `deployment-config/dev`. Within that folder, the instances will only apply objects targetted for their namespace.

## Helm Integration
If you are deploying a Helm Chart, then you should create a `HelmRelease` object YAML that describes the chart you want to apply and the configuration of that chart. The bip-archetypetest application provides an [example of a HelmRelease object](dev/bip-archetypetest-dev.yaml). Flux will apply this object to your namespace, which in turn will be read by the [Flux Helm operator](https://github.com/weaveworks/flux/blob/master/site/helm-integration.md) and it will then install the chart using Helm. For more information on writing your `HelmRelease` object YAML, see the [Flux Helm operator documentation](https://github.com/weaveworks/flux/blob/master/site/helm-integration.md).
