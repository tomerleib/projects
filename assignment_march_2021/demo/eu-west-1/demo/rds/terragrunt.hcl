include {
  path = "${find_in_parent_folders()}"
}
locals {
  account = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region  = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  env     = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  
  # Extract the variables we need for easy access
  account_name = local.account.locals.account_name
  account_id   = local.account.locals.aws_account_id
  aws_region   = local.region.locals.aws_region

  name = "${local.env.locals.environment}-db"

  }

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id = "vpc-00000000"
    cidr = "10.0.0.0/16"
    private_subnets = [
      "subnet-00000000",
      "subnet-00000001",
      "subnet-00000002",
    ]
  }
}

dependency "security_groups" {
  config_path = "../security_groups"
  mock_outputs = {
      this_security_group_id = "sg-123456"
  }
}

terraform {
    source = "github.com/terraform-aws-modules/terraform-aws-rds.git"
}

inputs = {
    identifier = local.name
    engine            = "mysql"
    engine_version    = "5.7.19"
    instance_class    = "db.t2.large"
    allocated_storage = 5
    port     = "3306"
    iam_database_authentication_enabled = false
    vpc_security_group_ids = ["${dependency.security_groups.outputs.this_security_group_id}"]
    subnet_ids = dependency.vpc.outputs.private_subnets
    maintenance_window = "Mon:00:00-Mon:03:00"
    backup_window = "03:00-06:00"
    create_db_option_group    = true
    create_db_parameter_group = true
    major_engine_version = "5.7"
    family = "mysql5.7"
    option_group_use_name_prefix = false
    option_group_name            = local.name
    parameter_group_name = local.name
    parameter_group_use_name_prefix = false
}