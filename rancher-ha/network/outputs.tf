output "rancher_com_arn" {
  value = "${aws_iam_server_certificate.rancher_com.arn}"
}

output "management_node_sgs" {
  value = "${join(",", list(module.management_sgs.management_node_sgs,
            module.bastion_sgs.bastion_id))}"
}

output "elb_sg_id" {
  value = "${module.management_sgs.elb_sg_id}"
}
