# Horizontal Pod Autoscaling

In Kubernetes, a HorizontalPodAutoscaler automatically updates a workload resource, with the aim of automatically scaling the workload to match demand.
Horizontal scaling means that the response to increased load is to deploy more Pods.
If the load decreases, and the number of Pods is above the configured minimum, the HorizontalPodAutoscaler instructs the workload resource to scale back down.

Kubernetes docs on Horizontal Pod Autoscaling can be found here:
* https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/

## Configuration
The template for a HorizontalPodAutoscaler can be found under [charts/bip-archetypetest/templates/hpa.yaml](../charts/bip-archetypetest/templates/hpa.yaml).

The following values for Horizontal Pod Autoscaling can be configured in the deployment configuration files for each environment:
* `hpa.enabled`: Determines whether HorizontalPodAutoscaler is deployed. Must be set to `true` to utilize Horizontal Pod Autoscaling.
* `replicaCount`: The minimum number of replicas that will be created.
* `hpa.maxReplicas`: The maximum number of replicas to scale up to.
* `hpa.cpu`: Metric for desired cpu utilization.
* `hpa.memory`: Metric for desired memory usage.
* `hpa.scaleDownStabilizationWindowSeconds`: This stabilization window is used in order to prevent the number of replicas from fluctuating frequently due to the dynamic nature of the metrics evaluated (known as thrashing or flapping).

## Example
Here is an example Horizontal Pod Autoscaling configuration within a [deployment configuration file](../deployment-config/dev/dev/bip-archetypetest-dev.yaml).

```
spec:
  values:
    hpa:
      enabled: true
      cpu: 100
      maxReplicas: 2
```