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
resource "aws_elb" "test_lb" {
  name = "project-terraform-lb"
  subnets = ["${var.public_subnets}"]

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 3
    unhealthy_threshold = 3
    timeout = 10
    target = "HTTP:80/index.html"
    interval = 30
  }

  security_groups = ["${aws_security_group.http.id}"]
}

resource "aws_launch_configuration" "my_lc" {
    name_prefix = "project_lc"
    image_id = "${data.aws_ami.ubuntu.id}"
    instance_type = "t2.micro"
    key_name = "${var.key_name}"
    user_data = <<-EOF
                #!/bin/bash
                apt-get install nginx apache2-utils -y
                systemctl enable nginx
                wget "https://s3-${var.region}.amazonaws.com/${aws_s3_bucket.my_bucket.id}/index.html" -P /var/www/html/
                EOF
    spot_price = "0.05"
}

resource "aws_autoscaling_group" "my_asg" {
    name_prefix = "test-asg"
    launch_configuration = "${aws_launch_configuration.my_lc.name}"
    min_size = 1
    max_size = 3
    health_check_type = "EC2"
    load_balancers = ["${aws_elb.test_lb.name}"]
    vpc_zone_identifier = ["${var.private_subnets}"]
    termination_policies = ["OldestLaunchConfiguration"]
}

resource "aws_autoscaling_policy" "asg_policy" {
    name = "asg_cpu_policy"
    policy_type = "TargetTrackingScaling"

    target_tracking_configuration {
      predefined_metric_specification {
        predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 40.0
  }
    autoscaling_group_name = "${aws_autoscaling_group.my_asg.name}"
}

output "Load Balancer Endpoint" {
  value = "${aws_elb.test_lb.dns_name}"
}
