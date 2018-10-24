variable "shared_credentials_file" {
  type = "string"
  default = "/home/user/.aws/credentials" # Location of the AWS credentials file, for example, /home/joe/.aws/credentials
}
variable "profile" {
  type = "string"
  default = "default" # change it if you use different name for the profile
}

variable "region" {
  type = "string"
  default = "eu-west-1"
}

variable "bucket_name" {
  type = "string"
  default = "my-test-bucket" # Change to bucket name
}

variable "key_name" {
  description = "Key name to be used with the launched EC2 instances."
  default = "mykey" # Name of the key-pair to use
}

variable "vpc_id" {
  description = "VPC ID to create the instance"
  type = "string"
  default = "vpc-xxxxxxxx" # Example vpc-xxxxxxx
}

variable "public_subnets" {
  description = "Public Subnets for the Load Balancer"
  type = "list"
  default = ["subnet-xxxxxxxx","subnet-xxxxxxxxxx"] # Example subnet-xxxxxx
}

variable "private_subnets" {
  description = "Private Subnets for the instances"
  type = "list"
  default = ["subnet-xxxxxxx","subnet-xxxxxxxxxxx"] # Example subnet-xxxxxx
}
variable "user" {
  description = "The user to display"
  type = "string"
  default = "Me" # Your name
}
