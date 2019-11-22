pipeline {
        agent {
            node {
                label 'git2consul'
            }
        }
        stages {
            stage('Configs to Dev') {
                environment {
                    CONSUL_ENDPOINT = 'consul.consul.svc.cluster.local'
                    CONSUL_PORT = '8500'
                }
                steps {
                    sh "git2consul_wrapper config/archetypetest git2consul.json"
                }
            }
        }
    }
