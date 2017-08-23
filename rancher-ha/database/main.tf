provider "aws" {
  region     = "${var.aws_region}"
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
}

module "database" {
  source = "../../modules/aws/data/rds"

  rds_instance_name  = "${var.aws_env_name}"
  security_group_name = "${var.aws_env_name}_sg_db"
  
  name = "${var.aws_env_name}"
  database_password  = "${var.database_password}"
  vpc_id             = "${var.aws_vpc_id}"
  source_cidr_blocks = "${concat(split(",", var.aws_subnet_cidrs))}"
  rds_instance_class = "${var.aws_rds_instance_class}"
  db_subnet_ids      = "${concat(split(",", var.aws_subnet_ids))}"
  rds_is_multi_az = "false"
  skip_final_snapshot = "true"
  backup_retention_period = 1
}
