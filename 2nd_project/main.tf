provider "aws" {
  shared_credentials_file = "${var.shared_credentials_file}"
  profile = "${var.profile}"
  region     = "${var.region}"
}

# Starting with S3
resource "aws_s3_bucket" "my_bucket" {
  bucket = "tomer-tf-test"
  acl    = "private"
}

resource "aws_s3_bucket_object" "index" {
  key          = "index.html"
  bucket       = "${aws_s3_bucket.my_bucket.id}"
  content      = "Hello! This is ${var.user}'s site!"
  content_type = "text/html"
  acl = "public-read"
}

# Now spin up the instance
resource "aws_security_group" "http" {
    name = "Allow HTTP"
    description = "Allow incoming HTTP access"
    vpc_id = "${var.vpc_id}"

    ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "myinstance" {
    ami = "${data.aws_ami.ubuntu.id}"
    instance_type = "t2.micro"
    vpc_security_group_ids = ["${aws_security_group.http.id}"]
    subnet_id = "${var.subnet_id}"
    associate_public_ip_address = true
    key_name = "tomer-test"
    user_data = <<-EOF
                #!/bin/bash
                apt-get install nginx apache2-utils -y
                wget "https://s3-${var.region}.amazonaws.com/${aws_s3_bucket.my_bucket.id}/index.html" -P /var/www/html/
                EOF

}
output "public_ip" {
  value = "${aws_instance.myinstance.public_ip}"
}
