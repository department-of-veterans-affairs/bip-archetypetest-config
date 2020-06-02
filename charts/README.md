# Helm Charts
This directory contains any custom [Helm Charts](https://helm.sh/docs/developing_charts/#charts) that have been developed for installing services related to this project.

## Testing Templates Locally
You can install `helm` and preview any changes to your templates locally.
For example: From within the chart directory `helm template --debug . --values <path-to-additional-values-file>` will 
output the processed templates as a multi-document yaml to stdout.

## Install
https://helm.sh/docs/intro/install/

### macOS
#### With Brew
`brew install helm`

### Windows
#### With Chocolatey
`choco install kubernetes-helm`
