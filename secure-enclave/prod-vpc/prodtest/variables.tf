provider "aws" {
  region = local.region
  version = "~> 3.0"
}

locals {
  tags = data.terraform_remote_state.fti-global.outputs.base_tags_out

  vpc_id = data.terraform_remote_state.fti-pvpc.outputs.pvpc_id_out

  cluster_id = data.terraform_remote_state.fti-pvpc.outputs.pvpc_cluster_id_out
  cluster_name = data.terraform_remote_state.fti-pvpc.outputs.pvpc_cluster_name_out
  listener_arn = data.terraform_remote_state.fti-pvpc.outputs.pvpc_alb_listener_arn_out

  region = data.terraform_remote_state.fti-global.outputs.region_out

  log_group_name = "/archetypetest/bip-archetypetestconfig/${var.environment}"
  log_group_prefix = "${var.environment}"

}


variable "container_port" {
  default = 8080
}

variable "desired_count" {
  default = 2
}

variable "environment" {
  default = "prodtest"
}
variable "cluster" {
  default = "prod"
}

variable "health_check_grace_period_seconds" {
  default = 300
}

variable "certificate_arn" {
  #This is only a placeholder value. Certificate must be created.
  default = "arn:aws-us-gov:acm:us-gov-west-1:999999999999:certificate/99999999-9999-9999-9999-999999999999"
}

variable "target_tracked_autoscaling" {
  type = map(string)
  default = {
              "ECSServiceAverageMemoryUtilization" = "80"
            }
}

variable "secure_enclave_container_role_arn" {
  #This is only a placeholder value. Container role must be created.
  default = "arn:aws-us-gov:iam::999999999999:role/project/project-prodtest-bip-archetypetestconfig-container-role"
}