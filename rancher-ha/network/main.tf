provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

resource "aws_iam_server_certificate" "rancher_com" {
  name_prefix       = "${var.aws_env_name}-certificate"
  certificate_body  = "${file("${var.server_cert_path}")}"
  private_key       = "${file("${var.server_key_path}")}"
  certificate_chain = "${file("${var.ca_chain_path}")}"

  lifecycle {
    create_before_destroy = true
  }
}

// https://github.com/rancher/terraform-modules/pull/13
module "management_sgs" {
  source = "../../modules/aws/network/security_groups/mgmt/ha"

  name        = "${var.aws_env_name}"
  vpc_id               = "${var.aws_vpc_id}"
  private_subnet_cidrs = "${var.aws_subnet_cidrs}"
}

module "bastion_sgs" {
  source = "../../modules/aws/network/security_groups/bastion"

  name                 = "${var.aws_env_name}"
  vpc_id               = "${var.aws_vpc_id}"
}
