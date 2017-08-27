output "rancher_com_arn" {
  value = "${aws_iam_server_certificate.rancher_com.arn}"
}

output "elb_sg_id" {
  value = "${module.management_sgs.elb_sg_id}"
}

output "management_node_sgs" {
  value = "${join(",", list(module.management_sgs.management_node_sgs, module.bastion_sgs.bastion_id))}"
}

output "vpc_id" {
  value = "${data.aws_vpc.vpc.id}"
}

output "subnet_ids" {
  value = "${var.aws_use_defaults == "true" ? join(",", data.aws_subnet_ids.default.ids) : var.aws_subnet_ids}"
}

output "subnet_cidrs" {
  value = "${var.aws_use_defaults == "true" ? join(",",data.aws_subnet.default.*.cidr_block) : var.aws_subnet_cidrs}"
}
