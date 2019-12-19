# BIP Reference External Configuration Repository
This repository contains deployment and runtime configuration data for the BIP Referencee Services. This repository serves as an example for how to structure other BIP service configuration repositories.

## Project Breakdown

### [Charts](charts)
The `charts` folder contains [Helm](https://helm.sh) Charts describing the Kubernetes objects needed to deploy our service.

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
