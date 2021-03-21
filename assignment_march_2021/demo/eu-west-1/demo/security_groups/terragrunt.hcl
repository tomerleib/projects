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

  }

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id = "vpc-00000000"
    vpc_cidr_block = "10.0.0.0/16"
    private_subnets = [
      "subnet-00000000",
      "subnet-00000001",
      "subnet-00000002",
    ]
  }
}

terraform {
    source = "github.com/terraform-aws-modules/terraform-aws-security-group.git"
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<-EOF
    provider "aws" {
      region = "${local.aws_region}"
    }
  EOF
}

inputs = {
    aws = {
        "region" = local.aws_region
    } 
    vpc_id = dependency.vpc.outputs.vpc_id
    subnets = dependency.vpc.outputs.private_subnets
    name = "MySQL SG"
    description = "Security Group for MySQL"
    ingress_with_cidr_blocks = [
    {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      description = "MySQL access from within VPC"
      cidr_blocks = dependency.vpc.outputs.vpc_cidr_block
    },
  ]

}