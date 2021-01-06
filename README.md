# BIP Reference External Configuration Repository
This repository contains deployment and runtime configuration data for the BIP Referencee Services. This repository serves as an example for how to structure other BIP service configuration repositories.

## Project Breakdown

### [Charts](charts)
The `charts` folder contains [Helm](https://helm.sh) Charts describing the Kubernetes objects needed to deploy our service.

#### [Jenkins Config](charts/jenkins-config)
The `charts/jenkins-config` folder contains an example chart that can be utilized to override Jenkins configuration options
that would otherwise need to be updated in [BIP Participant Intake](https://github.ec.va.gov/EPMO/bip-participant-intake).
This gives tenants additional power to augment their Jenkins deployment to suit their specific needs. However, an initial
change on the BIP Participant Intake side is required to make the Jenkins instance aware of the additional config map
used to provide overrides. The `tenant_overrides_enabled: true` entry must be added to the tenant's Ansible environment
file and then the Jenkins playbook must be rerun. The Jenkins instance will then include a volume mapped to the config map provided
in the Helm chart. If the Chart has not been processed yet and the config map is missing, Jenkins will fail to come up due to the unmapped
volume. Please reach out to E_BIP_Platform_Support@bah.com if you wish to have this configured for your project.

#### Overriding the Jenkins Global Pipeline Library
The keys in the tenant jenkins config map are provided under the 
`jenkinsConfig` Helm values as in [this](deployment-config/dev8/dev/jenkins-config.yaml) example.
For example, to override the Global Pipeline Library, the Helm value should have a key of `globalLibrary` which overrides
the `globalLibrary` entry [here](https://github.ec.va.gov/EPMO/bip-participant-intake/blob/development/ansible/roles/helm_install_item/templates/jenkins_values.yaml.j2).
```
  values:
    jenkinsConfig:
      globalLibrary: |
        unclassified:
          globalLibraries:
            libraries:
            - name: "jenkins-library"
              defaultVersion: "development"
              implicit: true
              retriever:
                modernSCM:
                  scm:
                    git:
                      credentialsId: "github"
                      remote: "https://github.ec.va.gov/EPMO/bip-jenkins-lib.git"
                      traits:
                      - "branchDiscoveryTrait"
```

All of the current defaults can also be viewed in the `<cluster>-<project_prefix>-jenkins` config map as well within your tenant namespace. 

The Helm values are translated into config map entries with a `.yaml` extension that are mapped in via a volume in the Jenkins pod
at runtime. See other items under `configScripts` [here](https://github.ec.va.gov/EPMO/bip-participant-intake/blob/development/ansible/roles/helm_install_item/templates/jenkins_values.yaml.j2)
for potential overrides, but realize that supportability of untested overrides is lacking.
If the items don't match exactly and Jenkins sees two items trying to configure the same thing, an error such as the following can occur:
```
io.jenkins.plugins.casc.ConfiguratorException: Found conflicting configuration at YamlSource: /var/jenkins_home/casc_configs/globalLibrary.yaml  in /var/jenkins_home/casc_configs/globalLibrary.yaml, line 11, column 14:
```

Other than the Global Pipeline Library, the following options are supported.

#### Overriding or adding additional Maven Agents
The configuration option `mavenSlave` in `jenkins_values.yaml.j2` configures the default list of agents. To override, an
agent version or add a new agent, you just need to ensure the config map key (i.e. filename) is alphabetically after `mavenSlave.yaml`. 
No `default` agent is necessary as it will inherit from the existing default. Note, in the Jenkins UI this will appear as two separate
"clouds". However, this has no negative affect on functionality. See the below example:
```
  values:
    jenkinsConfig:
      zzzz-alphatical-override-additionalSlaves: |
        jenkins:
          clouds:
            - kubernetes:
                name: kubernetes
                serverUrl: "https://kubernetes.default"
                namespace: "blue-dev"
                jenkinsUrl: "http://dev8-blue-jenkins:8080"
                jenkinsTunnel: "dev8-blue-jenkins-agent:50000"
                templates:
                  - name: "fortify-sca"
                    label: "fortify-sca"
                    nodeUsageMode: EXCLUSIVE
                    inheritFrom: "default"
                    containers:
                      - name: jnlp
                        image: "container-registry.dev8.bip.va.gov/ci/jenkins-slave-fortify:override"
                        alwaysPullImage: false
                        workingDir: "/home/jenkins"
                        command: ""
                        args: "^${computer.jnlpmac} ^${computer.name}"
                  - name: "go-proof-of-concept"
                    label: "go-proof-of-concept"
                    nodeUsageMode: EXCLUSIVE
                    inheritFrom: "default"
                    containers:
                      - name: jnlp
                        image: "container-registry.dev8.bip.va.gov/tenant/go-proof-of-concept:1.0.0"
                        alwaysPullImage: false
                        workingDir: "/home/jenkins"
                        command: ""
                        args: "^${computer.jnlpmac} ^${computer.name}"
```

Any new agent should be considered for inclusion for other tenants. As such, a pull request should be opened against
https://github.ec.va.gov/EPMO/bip-ci-k8s for eventual inclusion in the default list.

#### Defining Jobs via source code
Jobs can and should be defined via source code as well to make them resilient to disaster scenarios and provide
traceability. Similar to the config overrides above, this is defined in the HelmRelease under `jenkinsJobs` as in 
[this](deployment-config/dev8/dev/jenkins-config.yaml) example:
```
  values:
    jenkinsJobs:
      performance-test: |-
        <?xml version='1.1' encoding='UTF-8'?>
        <flow-definition plugin="workflow-job@2.32">
          <actions>
            <org.jenkinsci.plugins.pipeline.modeldefinition.actions.DeclarativeJobAction plugin="pipeline-model-definition@1.3.9"/>
            <org.jenkinsci.plugins.pipeline.modeldefinition.actions.DeclarativeJobPropertyTrackerAction plugin="pipeline-model-definition@1.3.9">
              <jobProperties/>
              <triggers/>
              <parameters>
                <string>agentLabel</string>
                <string>perfTestUrl</string>
                <string>perfOpts</string>
              </parameters>
              <options/>
            </org.jenkinsci.plugins.pipeline.modeldefinition.actions.DeclarativeJobPropertyTrackerAction>
          </actions>
          <description></description>
          <keepDependencies>false</keepDependencies>
          <properties>
            <hudson.model.ParametersDefinitionProperty>
              <parameterDefinitions>
                <hudson.model.StringParameterDefinition>
                  <name>perfTestUrl</name>
                  <description>Provide the base url to use to do performance testing if not specified in your Jenkinsfile or you desire to override the default. e.g. http://bip-reference-person-dev.blue-dev:8080</description>
                  <defaultValue></defaultValue>
                  <trim>false</trim>
                </hudson.model.StringParameterDefinition>
                <hudson.model.StringParameterDefinition>
                  <name>perfOpts</name>
                  <description>Override performance options. For example: -DjMeterTestFile=load-*.jmx as a regex match for which jmeter test definition files should be run.</description>
                  <defaultValue></defaultValue>
                  <trim>false</trim>
                </hudson.model.StringParameterDefinition>
                <hudson.model.StringParameterDefinition>
                  <name>agentLabel</name>
                  <description>Override the default agent label to run this test under.</description>
                  <defaultValue></defaultValue>
                  <trim>false</trim>
                </hudson.model.StringParameterDefinition>
              </parameterDefinitions>
            </hudson.model.ParametersDefinitionProperty>
            <hudson.plugins.jira.JiraProjectProperty plugin="jira@3.0.10"/>
          </properties>
          <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@2.74">
            <scm class="hudson.plugins.git.GitSCM" plugin="git@3.12.1">
              <configVersion>2</configVersion>
              <userRemoteConfigs>
                <hudson.plugins.git.UserRemoteConfig>
                  <url>https://github.ec.va.gov/EPMO/bip-reference-person</url>
                  <credentialsId>github</credentialsId>
                </hudson.plugins.git.UserRemoteConfig>
              </userRemoteConfigs>
              <branches>
                <hudson.plugins.git.BranchSpec>
                  <name>*/master</name>
                </hudson.plugins.git.BranchSpec>
              </branches>
              <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
              <submoduleCfg class="list"/>
              <extensions/>
            </scm>
            <scriptPath>Jenkinsfile.perfTest</scriptPath>
            <lightweight>true</lightweight>
          </definition>
          <triggers/>
          <disabled>false</disabled>
        </flow-definition>
```
Overrides of the default jobs provided via BIP-Participant-Intake work as long as the name is the same as the entry
under `default_jenkins_jobs` [here](https://github.ec.va.gov/EPMO/bip-participant-intake/blob/master/ansible/environments/000_cross_envs_vars).

#### Overriding Jenkins Plugins
Jenkins plugins can be defined in the jenkins-config HelmRelease under `jenkinsPlugins` in `plugins.txt`. 
Each plugin listed in `plugins.txt` must be formatted like the following with one plugin listed per line: `[pluginId]:[pluginVerison]`.

The desired `pluginOverrideMethod` can be defined in `pluginProperties.yaml`.
There are two `pluginOverrideMethod` values supported: `merge` and `overwrite`.
- `merge` is the default behavior. 
All plugins provided will be merged with those currently defined in BPI [here](https://github.ec.va.gov/EPMO/bip-participant-intake/blob/master/ansible/roles/helm_install_item/templates/jenkins_values.yaml.j2) under `installPlugins`. 
New plugins will be added while existing plugins will be updated to the version defined in `jenkins-config.yaml`.
- `overwrite` will result in all of the plugins from BPI being overwritten.
Only the list of plugins provided in `jenkins-config.yaml` will be installed. 

An example `jenkinsPlugins` configuration can be found [here](deployment-config/dev8/dev/jenkins-config.yaml):
```
  values:
    jenkinsPlugins:
      plugins.txt: |
        powershell:1.4
        scriptler:3.1
        mailer:1.32
        token-macro:2.12
      pluginProperties.yaml: |
        pluginOverrideMethod: merge
```
In the example above, the tenant is installing two new plugins (powershell and scriptler) and 
updating the versions of two existing plugins (mailer and token-macro) by using the merge `pluginOverrideMethod`.

### Health Check Configuration
Health Checks are used to determine if the application is in a healthy state.
Enabled health checks will be found at the `/actuator/health` endpoint.
If any individual health check returns a status of `DOWN`, the entire `/actuator/health` endpoint will also return a status of `DOWN`, so configure desired health checks accordingly.

#### Default Health Check Descriptions:
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

#### Health Check Properties:
Defaults for the Health Checks described above are defined in the `bip-archetypetest.yml` file in the service repo.
If these default values need to be configured differently in each environment, they can be added to the appropriate yml files in the `/config` directory (example: [bip-archetypetest-dev.yml](config/dev/bip-archetypetest-dev.yml)).
```
spring:
  cloud:
    discovery:
      client:
        composite-indicator:
          enabled: false
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

#### Validating Health Check Configuration
To validate that the health check properties have been updated appropriately check the `actuator/env` endpoint.
To validate that the health checks are disabled/enabled as desired check the `actuator/health` endpoint.

### Liveness and Readiness Probe Configuration
__Liveness Probes__ are used to determine if a container is in an unhealthy state and needs to be restarted.

__Readiness Probes__ are used to determine when a container is ready to start accepting traffic. 
A Pod is considered ready when all of its containers are ready. 
One use of this signal is to control which Pods are used as backends for Services. When a Pod is not ready, it is removed from Service load balancers.

Default values for Liveness and Readiness probes are defined in [values.yaml](charts/bip-archetypetest/values.yaml).
If these values need to be configured differently in each environment, add these properties to the appropriate deployment config yaml files (example: [bip-archetypetest-dev.yaml](deployment-config/dev8/dev/bip-archetypetest-dev.yaml)).
```
values:
  ...
  livenessProbe: |
    httpGet:
      path: /actuator/info
      port: http
    initialDelaySeconds: 45
    periodSeconds: 5
    failureThreshold: 6
  readinessProbe: |
    httpGet:
      path: /actuator/health
      port: http
    initialDelaySeconds: 45
    periodSeconds: 5
    failureThreshold: 6
```
* __httpGet__: The probe will perform an HTTP GET request on the specified `path` and `port`. Any code greater than or equal to 200 and less than 400 returned indicates success. Any other code indicates failure.
* __initialDelaySeconds__: Number of seconds after the container has started before liveness or readiness probes are initiated. Defaults to 0 seconds. Minimum value is 0.
* __periodSeconds__: How often (in seconds) to perform the probe. Default to 10 seconds. Minimum value is 1.
* __failureThreshold__: The number of times readiness/liveness checks will be attempted by probes before giving up. When the failure threshold is reached for a liveness probe, the container is restarted. When the failure threshold is reached for a readiness probe, the Pod will be marked Unready. Defaults to 3. Minimum value is 1.

More info on Liveness and Readiness probes can be found [here](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/).

### [Config](config)
The `config` folder contains the runtime configuration for our service. These key/value pairs are loaded into Consul using [git2consul](https://github.com/breser/git2consul).

__Note__: The consul.config.prefix property in the deployment configs may need to be updated depending on where the values are being stored in Consul.

### [Deployment Config](deployment-config)
The `deployment-config` folder contains Helm Release configuration files used to configure our Helm deployment packages for different environments. It also contains bootstrapping configuration options that cannot be provided through Consul.

### Service Repository Configuration
Default runtime configuration is often embedded in the application under the `src/main/resources/bip-<service>.yml` file.  Default bootstrapping configuration is often embedded in the application under the `src/main/resources/bootstrap.yml` file. Examples of these files can be found [here](https://github.ec.va.gov/EPMO/bip-archetype-service/tree/master/bip-archetype-service-archetypetest/bip-archetypetest/src/main/resources).

### [Flux Service](flux-service)
The `flux-service` folder contains YAML files for installing Flux and Tiller into Openshift and Kubernetes in such a way that those services have access to only a single namespace. This directory is not needed for other projects. Its likely this directory will move to a Platform repository at a later date.

# Branching and Promotion

## Development Branch
The `development` branch is monitored by the Dev cluster and can be updated by an contributer to this repository. The Dev cluster will be monitoring changes to the `/config/dev` and `/deployment-config/dev` folders. For contributing to the `development` branch it is generally recommended to create a new feature branch, make your changes and open a Pull Request (PR) against the `development` branch. This should then be reviewed by the tech lead and merged once approved.

## Master Branch
The `master` branch is monitored by the Staging and Production clusters and can only be updated by a member of the ProdOps team. The Staging cluster will be monitoring changes to the `/config/stage` and `/deployment-config/stage` folders. The Production cluster will be monitoring changes to the `/config/prod` and `/deployment-config/prod` folders.
To promote changes to the Staging or Production clusters, a contributor should create a new feature branch, commit their changes, and then open a Pull Request (PR) against the `master` branch. This PR will be reviewed by a member of the ProdOps team and if approved, merged into the `master` branch.

# Secrets Management
Secrets needed you your application at runtime will be managed in Vault by the platform team. Secrets would include authentication credentials, private keys and other sensitive application information that cannot be bundled in the application container image.

## Adding New Secrets
As a development team when you identify the need for a new application secret, the process for getting the Secret created in Dev Vault is to:

* _Login to the vault dev environment [here](https://vault.dev8.bip.va.gov) using your ldap credentials. (Note only admins can add/update vault)_
* _Navigate to your projects vault root directory, e.g. https://vault.dev8.bip.va.gov/ui/vault/secrets/secret/list/blue/_
* _Create the key/value pairs under <service_name>/<env>, e.g. bip-reference-person/dev_
* _Create the key/value for the int and test environments as well if necessary_
  
  
In the DR for the stage or prod environment, include a request for a new Secret for your application in Vault. Be sure to include:
* _Vault Path for secret_
* _Application property name for the secret value_
* _How to obtain the correct secret value_

Secrets must be provided over a secured channel like an encrypted email using only VA email addresses or over VA skype. 

## Promoting Secrets to Staging and Production clusters
When a new secret is requested for the Dev environment, the ProdOps team should go ahead and create secrets in the Staging and Production vault instances as well.
