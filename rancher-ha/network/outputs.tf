output "rancher_com_arn" {
  value = "${aws_iam_server_certificate.rancher_com.arn}"
}

output "elb_sg_id" {
  value = "${aws_security_group.management_elb.id}"
}

output "management_node_sgs" {
  value = "${join(",", list(aws_security_group.management_allow_elb.id,
            aws_security_group.management_allow_internal.id,
            module.bastion_sgs.bastion_id)))}"
}
