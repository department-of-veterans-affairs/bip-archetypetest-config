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

### [Config](config)
The `config` folder contains the runtime configuration for our service. These key/value pairs are loaded into Consul using [git2consul](https://github.com/breser/git2consul).

### [Deployment Config](deployment-config)
The `deployment-config` folder contains HelmObject configuration files used to configure our Helm deployment packages for different environments.

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
