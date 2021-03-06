provider "aws" {
  shared_credentials_file = "~/.aws/credentials"
  region                  = "eu-west-1"
}

resource "aws_emr_cluster" "tf-test-cluster" {
  name          = "terraform-test-v1"
  release_label = "emr-5.13.0"
  applications  = ["Spark", "Hive", "Hadoop", "Zookeeper", "Hue", "Pig", "Tez", "HBase", "Oozie", "Livy"]

  ec2_attributes {
    subnet_id                         = "subnet-8249e1f4"
    emr_managed_master_security_group = "${aws_security_group.master_sg.id}"
    emr_managed_slave_security_group  = "${aws_security_group.slave_sg.id}"
    instance_profile                  = "arn:aws:iam::815199475415:instance-profile/EMR_EC2_DefaultRole"
    key_name                          = "emr"
    service_access_security_group     = "${aws_security_group.service_sg.id}"
  }

  #master_instance_type = "m4.large"
  #core_instance_type   = "m4.large"
  #core_instance_count  = 1
  ebs_root_volume_size = 50

  log_uri = "${var.log_uri}"

  instance_group {
    instance_role  = "MASTER"
    instance_type  = "m4.large"
    instance_count = "1"

    ebs_config {
      size                 = "100"
      type                 = "gp2"
      volumes_per_instance = 1
    }
  }

  instance_group {
    instance_role  = "CORE"
    instance_type  = "m4.large"
    instance_count = "1"

    ebs_config {
      size                 = "100"
      type                 = "gp2"
      volumes_per_instance = 1
    }
  }

  tags {
    Name = "tf-emr"
  }

  service_role = "arn:aws:iam::815199475415:role/EMR_DefaultRole"
}

resource "aws_security_group" "master_sg" {
  name                   = "emr-dev-terraform-master-sg"
  description            = "EMR Master Security Group(autogenerated)"
  vpc_id                 = "vpc-584e913c"
  revoke_rules_on_delete = "true"

  # ingress {
  #   from_port   = 0
  #   to_port     = 0
  #   protocol    = "-1"
  #   security_group_id = "${aws_security_group.slave_sg.id}"
  # },
  ingress {
    from_port   = 8888
    to_port     = 8888
    protocol    = "tcp"
    cidr_blocks = ["192.168.2.0/24", "192.168.7.0/24", "192.168.9.0/24"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["192.168.2.0/24", "192.168.7.0/24", "192.168.9.0/24"]
  }

  ingress {
    from_port   = 1000
    to_port     = 1000
    protocol    = "tcp"
    cidr_blocks = ["192.168.2.0/24", "192.168.7.0/24", "192.168.9.0/24"]
  }

  # ingress {
  #   from_port = 0
  #   to_port = 8443
  #   protocol = "tcp"
  #   security_group_id = "sg-ead8cf90"
  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "slave_sg" {
  name                   = "emr-dev-terraform-slave-sg"
  description            = "EMR dev slave security group(autogenerated)"
  vpc_id                 = "vpc-584e913c"
  revoke_rules_on_delete = "true"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "service_sg" {
  name                   = "emr-dev-terraform-serviceaccess-sg"
  description            = "EMR Dev Service Access Security Group EMR(autogenerated)"
  vpc_id                 = "vpc-584e913c"
  revoke_rules_on_delete = "true"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

provider "spotinst" {
  token   = "${var.spotinst_token}"
  account = "${var.spotinst_account}"
}

resource "spotinst_mrscaler" "emr-dev-spotinst-scaler" {
  name                = "emr-dev-mr-scaler"
  description         = "${var.COMMIT}"
  region              = "eu-west-1"
  strategy            = "wrap"
  cluster_id          = "${aws_emr_cluster.tf-test-cluster.id}" # todo: Need to add step to get the cluster_id
  task_instance_types = ["c3.xlarge", "c4.xlarge"]
  task_target         = 2
  task_minimum        = 0
  task_maximum        = 4
  task_lifecycle      = "SPOT"

  task_ebs_block_device {
    volumes_per_instance = 1
    volume_type          = "gp2"
    size_in_gb           = 100
  }
}
