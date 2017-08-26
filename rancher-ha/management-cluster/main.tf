provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

data "terraform_remote_state" "network" {
  backend = "s3"

  config {
     bucket = "${var.aws_s3_bucket}"
     key = "${var.aws_env_name}/network/terraform.tfstate"
     region = "${var.aws_region}"
  }
}

data "terraform_remote_state" "database" {
  backend = "s3"

  config {
     bucket = "${var.aws_s3_bucket}"
     key = "${var.aws_env_name}/database/terraform.tfstate"
     region = "${var.aws_region}"
  }
}

data "aws_ami" "os" {
  most_recent      = true

  filter {
    name = "architecture"
    values = ["x86_64"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  name_regex = "^${var.operating_system}"
}

data "template_file" "userdata" {
  template = "${file("${path.module}/files/userdata.template")}"

  vars {
    database_endpoint = "${element(split(":", data.terraform_remote_state.database.endpoint),0)}"
    ip-addr           = "local-ipv4"
    database_name     = "${data.terraform_remote_state.database.database}"
    database_user     = "${data.terraform_remote_state.database.username}"
    database_password = "${data.terraform_remote_state.database.password}"
    rancher_version   = "${var.rancher_version}"
    docker_version = "${var.docker_version}"
    rhel_selinux = "${var.rhel_selinux}"
    rhel_docker_native = "${var.rhel_docker_native}"
  }
}

module "management_elb" {
  source = "../../modules/aws/network/components/elb"

  name                    = "${var.aws_env_name}-api-mgmt"
  security_groups         = "${data.terraform_remote_state.network.elb_sg_id}"
  public_subnets          = "${var.aws_subnet_ids}"
  instance_ssl_port       = "8080"
  proxy_proto_port_string = "80,8080"
  instance_http_port      = "80"

  health_check_target     = "HTTP:8080/v1/scripts/api.crt"

  ssl_certificate_arn     = "${data.terraform_remote_state.network.rancher_com_arn}"
}

module "compute" {
  source = "../../modules/aws/compute/ha-mgmt"

  vpc_id          = "${var.aws_vpc_id}"
  name            = "${var.aws_env_name}-management"
  //ami_id          = "${var.aws_ami_id}"
  ami_id          = "${data.aws_ami.os.image_id}"
  instance_type   = "${var.aws_instance_type}"
  ssh_key_name    = "${var.key_name}"
  security_groups = "${join(",", list(data.terraform_remote_state.network.management_node_sgs))}"
  lb_ids          = "${join(",", list(module.management_elb.elb_id))}"
  spot_enabled    = "${var.spot_enabled}"

  subnet_ids                  = "${var.aws_subnet_ids}"
  subnet_cidrs                = "${var.aws_subnet_cidrs}"
  externally_defined_userdata = "${data.template_file.userdata.rendered}"
  health_check_type           = "${var.health_check_type}"

  scale_min_size         = "${var.scale_min_size}"
  scale_max_size         = "${var.scale_max_size}"
  scale_desired_size     = "${var.scale_desired_size}"
}

resource "aws_route53_record" "www" {
   zone_id = "${var.zone_id}"
   name = "${var.domain_name}"
   type = "CNAME"
   ttl = "30"
   records = ["${module.management_elb.dns_name}"]
}
