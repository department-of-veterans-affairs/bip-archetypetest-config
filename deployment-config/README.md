# Deployment Configuration
Deployments on the BIP platform are done using [Flux](https://github.com/weaveworks/flux) and [Helm](https://helm.sh). Flux is configured to monitor this Git repository for changes. When changes are detected, Flux will read the Kubernetes YAML files in the configured repository location and apply them to the Kubernetes cluster.

## Directory Structure
Each namespace used by your project has its own instances of Flux and Helm that is monitoring a specific folder within this repository. Instances are configured to look at `deployment-config/{cluster}`. For example the `Dev` cluster looks at `deployment-config/dev`. Within that folder, the instances will only apply objects targetted for their namespace.

## Helm Integration
If you are deploying a Helm Chart, then you should create a `HelmRelease` object YAML that describes the chart you want to apply and the configuration of that chart. The bip-archetypetest application provides an [example of a HelmRelease object](dev/bip-archetypetest-dev.yaml). Flux will apply this object to your namespace, which in turn will be read by the [Flux Helm operator](https://github.com/weaveworks/flux/blob/master/site/helm-integration.md) and it will then install the chart using Helm. For more information on writing your `HelmRelease` object YAML, see the [Flux Helm operator documentation](https://github.com/weaveworks/flux/blob/master/site/helm-integration.md).

## Health Checks
Health Checks are used to determine if the application is in a healthy state.
Enabled health checks will be found at the `/actuator/health` endpoint.
If any individual health check returns a status of `DOWN`, the entire `/actuator/health` endpoint will also return a status of `DOWN`, so configure desired health checks accordingly. 
###Default Health Check Descriptions:
* __consul__:
    * Health check for Consul service instances.
    * `management.health.consul.enabled`
    * __Causes 500 errors to occur for `/actuator/health` endpoint when Consul is down.__
    * More info [here](https://cloud.spring.io/spring-cloud-consul/multi/multi_spring-cloud-consul-discovery.html#_http_health_check).
* __composite-indicator__:
    * Health check for Consul Discovery Client. Details includes a list of all services registered in Consul.
    * `spring.cloud.discovery.client.composite-indicator.enabled`
    * __Causes 500 errors to occur for `/actuator/health` endpoint when Consul is down.__
    * More info [here](https://spring.getdocs.org/en-US/spring-cloud-docs/spring-cloud-commons/cloud-native-applications/spring-cloud-commons:-common-abstractions/discovery-client.html#_health_indicator).
* __vault__:
    * Health check returning status of Vault server.
    * `management.health.vault.enabled`
    * __Causes 500 errors to occur for `/actuator/health` endpoint when Vault is down.__
    * More info [here](https://cloud.spring.io/spring-cloud-vault/reference/html/).
* __diskSpace__:
    * A HealthIndicator that checks available disk space and reports a status of Status.DOWN when it drops below a configurable threshold.
    * `management.health.diskspace.enabled`
    * More info [here](https://docs.spring.io/spring-boot/docs/current/api/org/springframework/boot/actuate/system/DiskSpaceHealthIndicator.html).
* __refreshScope__:
    * Health indicator for the refresh scope and configuration properties rebinding. If an environment change causes a bean to fail in instantiate or bind this indicator will generally say what the problem was and switch to DOWN.
    * `management.health.refresh.enabled`
    * More info [here](https://www.javadoc.io/doc/org.springframework.cloud/spring-cloud-commons-parent/1.1.8.RELEASE/org/springframework/cloud/health/RefreshScopeHealthIndicator.html).
* __db__:
    * HealthIndicator that tests the status of a DataSource and optionally runs a test query.
    * `management.health.db.enabled`
    * More info [here](https://docs.spring.io/spring-boot/docs/current/api/org/springframework/boot/actuate/jdbc/DataSourceHealthIndicator.html).
* __hystrix__:
    * Health indicator for Hystrix indicating the state of connected circuit breakers.
    * `management.health.hystrix.enabled`
    * More info [here](https://cloud.spring.io/spring-cloud-netflix/multi/multi__circuit_breaker_hystrix_clients.html#_health_indicator).
* __rateLimiters__:
    * Health indicator for Resilience4j RateLimiters.
    * `management.health.ratelimiters.enabled`
    * More info on RateLimiters [here](https://resilience4j.readme.io/docs/ratelimiter).
    * More info on Resilience4j health endpoints [here](https://resilience4j.readme.io/docs/getting-started-3#section-health-endpoint).
* __circuitBreakers__:
    * Health indicator for Resilience4j CircuitBreakers. A closed CircuitBreaker state is mapped to UP, an open state to DOWN and a half-open state to UNKNOWN.
    * `management.health.circuitbreakers.enabled`
    * More info on CircuitBreakers [here](https://resilience4j.readme.io/docs/circuitbreaker).
    * More info on Resilience4j health endpoints [here](https://resilience4j.readme.io/docs/getting-started-3#section-health-endpoint).
###Configuring Health Checks:
To configure the health checks described above, these vars must be added to the [deployment template](../charts/bip-archetypetest/templates/deployment.yaml) under `env`.
```
env:
  {{- if kindIs "invalid" .Values.management.health.consul.enabled | not }}
  - name: management.health.consul.enabled
    value: {{ .Values.management.health.consul.enabled | quote }}
  {{- end }}
  {{- if kindIs "invalid" .Values.consul.discovery.client.compositeIndicator.enabled | not }}
  - name: spring.cloud.discovery.client.composite-indicator.enabled
    value: {{ .Values.consul.discovery.client.compositeIndicator.enabled | quote }}
  {{- end }}
  {{- if kindIs "invalid" .Values.management.health.vault.enabled | not }}
  - name: management.health.vault.enabled
    value: {{ .Values.management.health.vault.enabled | quote }}
  {{- end }}
  {{- if kindIs "invalid" .Values.management.health.db.enabled | not }}
  - name: management.health.db.enabled
    value: {{ .Values.management.health.db.enabled | quote }}
  {{- end }}
  {{- if kindIs "invalid" .Values.management.health.diskspace.enabled | not }}
  - name: management.health.diskspace.enabled
    value: {{ .Values.management.health.diskspace.enabled | quote }}
  {{- end }}
  {{- if kindIs "invalid" .Values.management.health.refresh.enabled | not }}
  - name: management.health.refresh.enabled
    value: {{ .Values.management.health.refresh.enabled | quote }}
  {{- end }}
  {{- if kindIs "invalid" .Values.management.health.ratelimiters.enabled | not }}
  - name: management.health.ratelimiters.enabled
    value: {{ .Values.management.health.ratelimiters.enabled | quote }}
  {{- end }}
  {{- if kindIs "invalid" .Values.management.health.circuitbreakers.enabled | not }}
  - name: management.health.circuitbreakers.enabled
    value: {{ .Values.management.health.circuitbreakers.enabled | quote }}
  {{- end }}
  {{- if kindIs "invalid" .Values.management.health.hystrix.enabled | not }}
  - name: management.health.hystrix.enabled
    value: {{ .Values.management.health.hystrix.enabled | quote }}
  {{- end }}
```

Once these vars are added to the template, the values can be defined in the desired deployment-config yaml files ([dev example](dev8/dev/bip-archetypetest-dev.yaml)) under `values.management.health`:
```
  values:
    ...
    management:
      health:
        consul:
          enabled: false
        vault:
          enabled: false
        db:
          enabled: false
        diskspace:
          enabled: true
        refresh:
          enabled: true
        ratelimiters:
          enabled: false
        circuitbreakers:
          enabled: false
        hystrix:
          enabled: false
```

Except the `composite-indicator` health check which is configured under `values.consul.discovery.client`:
```
  values:
    ...
    consul:
      ...
      discovery:
        ...
        client:
          compositeIndicator:
            enabled: false
``` 

###Validating Health Check Configuration
To validate that the health check vars have been updated appropriately check the `actuator/env` endpoint.
To validate that the health checks are disabled/enabled as desired check the `actuator/health` endpoint.

###Liveness and Readiness Probes
__Liveness Probes__ are used to determine if a container is in an unhealthy state and needs to be restarted.

__Readiness Probes__ are used to determine when a container is ready to start accepting traffic. 
A Pod is considered ready when all of its containers are ready. 
One use of this signal is to control which Pods are used as backends for Services. When a Pod is not ready, it is removed from Service load balancers.

Liveness and Readiness Probe default values are configured in the [deploymentTemplate](../charts/bip-archetypetest/templates/deployment.yaml).
```
env:
  ...
  livenessProbe:
    httpGet:
      path: /actuator/info
      port: http
    initialDelaySeconds: 45
    periodSeconds: 5
  readinessProbe:
    httpGet:
      path: /actuator/health
      port: http
    initialDelaySeconds: 45
    periodSeconds: 5
```
* __httpGet__: The probe will perform an HTTP GET request on the specified `path` and `port`. Any code greater than or equal to 200 and less than 400 returned indicates success. Any other code indicates failure.
* __initialDelaySeconds__: Number of seconds after the container has started before liveness or readiness probes are initiated. Defaults to 0 seconds. Minimum value is 0.
* __periodSeconds__: How often (in seconds) to perform the probe. Default to 10 seconds. Minimum value is 1.

More info can be found [here](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/).