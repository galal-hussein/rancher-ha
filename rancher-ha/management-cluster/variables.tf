variable "rancher_hostname" {}

variable "domain_name" {}

variable "aws_access_key" {}

variable "aws_secret_key" {}

variable "aws_region" {}

variable "aws_s3_bucket" {}

variable "aws_ami_id" {}

variable "aws_env_name" {}

variable "aws_instance_type" {}

variable "rancher_version" {}

variable "api_ui_version" {}

variable "spot_enabled" {}

variable "zone_id" {}

variable "health_check_type" {
  default = "EC2"
}

variable "docker_version" {}

variable "rhel_selinux" {}

variable "rhel_docker_native" {}

variable "key_name" {}
