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
//module "management_sgs" {
//  source = "../../modules/aws/network/security_groups/mgmt/ha"

//  vpc_id               = "${var.aws_vpc_id}"
//  private_subnet_cidrs = "${var.aws_subnet_cidrs}"
//}

resource "aws_security_group" "management_elb" {
  name        = "${var.aws_env_name}-management_elb_sg"
  description = "Allow ports rancher "
  vpc_id      = "${var.aws_vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "management_allow_elb" {
  name        = "${var.aws_env_name}-rancher_ha_allow_elb"
  description = "Allow Connection from elb"
  vpc_id      = "${var.aws_vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = ["${aws_security_group.management_elb.id}"]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = ["${aws_security_group.management_elb.id}"]
  }

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = ["${aws_security_group.management_elb.id}"]
  }
}

resource "aws_security_group" "management_allow_internal" {
  name        = "rancher_ha_allow_internal"
  description = "Allow Connection from internal"
  vpc_id      = "${var.aws_vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${split(",", var.aws_subnet_cidrs)}"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${split(",", var.aws_subnet_cidrs)}"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${split(",", var.aws_subnet_cidrs)}"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["${split(",", var.aws_subnet_cidrs)}"]
  }

  ingress {
    from_port   = 9345
    to_port     = 9345
    protocol    = "tcp"
    cidr_blocks = ["${split(",", var.aws_subnet_cidrs)}"]
  }
}


module "bastion_sgs" {
  source = "../../modules/aws/network/security_groups/bastion"

  name                 = "${var.aws_env_name}"
  vpc_id               = "${var.aws_vpc_id}"
}
