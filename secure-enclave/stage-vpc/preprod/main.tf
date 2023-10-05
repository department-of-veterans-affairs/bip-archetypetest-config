#Terraform configuration settings
terraform {
  backend "s3" {
    #s3 bucket containing terraform states. Unique key for each project/service per environment.
    bucket         = "fti-tf-states-stage"
    key            = "terraform.tfstate.bip-archetypetest-preprod-environment"
    dynamodb_table = "fti-tf-lock-stage"
    region         = "us-gov-west-1"
    encrypt        = true
  }
}

#Data blocks are used to set locals in variables.tf.
data "terraform_remote_state" "fti-svpc" {
  backend = "s3"
  config = {
    bucket         = "fti-tf-states-stage"
    key            = "terraform.tfstate.fti-stage-vpc"
    dynamodb_table = "fti-tf-lock-stage"
    region         = "us-gov-west-1"
    encrypt        = true
  }
}

data "terraform_remote_state" "fti-global" {
  backend = "s3"
  config = {
    bucket         = "fti-tf-states-global"
    key            = "terraform.tfstate.fti-global"
    dynamodb_table = "fti-tf-lock-global"
    region         = "us-gov-west-1"
    encrypt        = true
  }
}

#Unique log group defined for each project/service per environment.
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group
resource "aws_cloudwatch_log_group" "secure_enclave_deploy_log_group" {
  #Local values are defined in variables.tf file
  name = local.log_group_name
  retention_in_days = 0
  tags = local.tags
}

#Consul and vault secrets were created manually.
data "aws_secretsmanager_secret" "consul-token" {
  name = "preprod/bip-archetypetest/consul-acl-token"
}
data "aws_secretsmanager_secret" "vault-token" {
  name = "preprod/bip-archetypetest/vault-token"
}

#Calls module for creating task container definition resource
module "ecs_task_container_definition" {
     source = "github.com/cloudposse/terraform-aws-ecs-container-definition?ref=0.47.0"
     container_cpu = 300
     container_memory_reservation = 1024
     #Update with appropriate image tag. Defaults to latest.
     container_image = "container-registry.stage.bip.va.gov/archetypetest/bip-archetypetest:latest"
     container_name = "preprod-bip-archetypetest-container"
     #Secret values pulled from data definitions above
     secrets = [
       {
         name = "spring.cloud.consul.config.acl-token"
         valueFrom = "${data.aws_secretsmanager_secret.consul-token.arn}:TOKEN::"
       },
       {
         name = "spring.cloud.consul.discovery.acl-token"
         valueFrom = "${data.aws_secretsmanager_secret.consul-token.arn}:TOKEN::"
       },
       {
         name = "spring.cloud.vault.token"
         valueFrom = "${data.aws_secretsmanager_secret.vault-token.arn}:TOKEN::"
       }
     ]

     log_configuration = {
       logDriver = "awslogs"
       options = {
         "awslogs-group"         = local.log_group_name
         "awslogs-region"        = local.region
         "awslogs-stream-prefix" = local.log_group_prefix
       } 
     }
     port_mappings = [
                        {
                          containerPort = 8080
                          hostPort = 0
                          protocol = "tcp"
                        }
                      ]
     environment = [
                        {
                          name = "spring.cloud.consul.enabled"
                          value = "true"
                        },
                        {
                          name = "spring.cloud.consul.config.enabled"
                          value = "true"
                        },
                        {
                          name = "spring.cloud.consul.config.failFast"
                          value = "true"
                        },
                        {
                          name = "spring.cloud.consul.discovery.enabled"
                          value = "true"
                        },
                        {
                          name = "spring.cloud.vault.enabled"
                          value = "true"
                        },
                        {
                          name = "spring.cloud.vault.failFast"
                          value = "true"
                        },
                        {
                          name = "spring.cloud.vault.kv.application-name"
                          value = "archetypetest/bip-archetypetest"
                        },
                        {
                          name = "spring.profiles.active"
                          value = "preprod"
                        },
                        {
                          name = "spring.cloud.consul.config.prefix"
                          value = "config/archetypetest"
                        },
                        {
                          name = "spring.cloud.consul.host"
                          value = "consul-fti.stage.bip.va.gov"
                        },
                        {
                          name = "spring.cloud.consul.port"
                          value = 443
                        },
                        {
                          name = "spring.cloud.consul.scheme"
                          value = "https"
                        },
                        {
                          name = "spring.cloud.vault.host"
                          value = "vault.stage.bip.va.gov"
                        },
                        {
                          name = "spring.cloud.vault.port"
                          value = 443
                        },
                        {
                          name = "spring.cloud.vault.scheme"
                          value = "https"
                        },
                        {
                          name = "spring.cloud.vault.authentication"
                          value = "token"
                        },
                        {
                          name = "spring.cloud.vault.kubernetes.role"
                          value = "archetypetest-read"
                        },
                        {
                          name = "spring.cloud.vault.kubernetes.service-account-token-file"
                          value = "/var/run/secrets/kubernetes.io/serviceaccount/token"
                        },
                        {
                          name = "JAVA_TOOL_OPTIONS"
                          value = "-XX:+PrintFlagsFinal -XX:MaxRAMPercentage=67.0 -Djavax.net.ssl.trustStorePassword=changeit -Djavax.net.ssl.trustStore=/var/run/secrets/java.io/keystores/truststore.jks"
                        }
     ]
}

#Calls module for creating secure enclave resources.
module "preprod_bip_archetype_test_container" {
  source = "github.com/department-of-veterans-affairs/bip-fti-infrastructure//src/terraform/modules/secure-enclave-deploy-ecs?ref=v1.0.3"

  deployment_name                   = "bip-archetypetest"
  container_definition              = module.ecs_task_container_definition.json_map_encoded_list
  listener_arn                      = local.listener_arn
  cert_arn                          = var.certificate_arn
  container_port                    = var.container_port
  cluster_id                        = local.cluster_id
  cluster_name                      = local.cluster_name
  desired_count                     = var.desired_count
  vpc_id                            = local.vpc_id
  host_pattern_match_for_listener   = ["*bip-archetypetest-preprod.fti-stage.*"]
  environment                       = var.environment
  cluster                           = var.cluster
  healthcheck_endpoint              = "/actuator/info"
  health_check_grace_period_seconds = var.health_check_grace_period_seconds
  scaling_policies                  = var.target_tracked_autoscaling
  secure_enclave_container_role_arn = var.secure_enclave_container_role_arn
  tg_protocol                       = "HTTP"
  tags = merge(
    {
      "Environment" = "STAGE",
      "env"         = "preprod"
      "ResTag"      = "PreProd BIP-ARCHETYPETEST Container",
      "Role"        = "Web"
    },
    local.tags
  )
}
