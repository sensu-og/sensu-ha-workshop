variable "username" {}
variable "key_path" {}

variable "backend_instances" {
  description = "Number of Sensu Enterprise instances to deploy. Multiple backends are not automatically configured for HA."
  default = 1
}

variable "region" {
  default = "us-west-2"
}

variable "centos_amis" {
  type = "map"
  default = {
    "us-east-1" = "ami-4bf3d731"
    "us-east-2" = "ami-e1496384"
    "us-west-1" = "ami-65e0e305"
    "us-west-2" = "ami-a042f4d8"
  }
}

provider "aws" {
  region     = "${var.region}"
}
resource "aws_security_group" "poc" {
  name        = "poc"
  description = "Allow inbound traffic"
  vpc_id      = "${aws_vpc.main.id}"

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    ipv6_cidr_blocks = ["::/0"]
  }
// SSH Access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description = "SSH Access"
  }
// backend dashboard listener port
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description = "backend dashboard listener port"
  }
// backend rabbitmq listener port
  ingress {
    from_port   = 5671
    to_port     = 5672
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description = "backend rabbitmq listener port"
  }
// agent socket
  ingress {
    from_port   = 3030
    to_port     = 3030
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description = "agent socket"
  }
  ingress {
    from_port   = 3030
    to_port     = 3030
    protocol    = "UDP"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description = "agent socket"
  }
// agent http api
  ingress {
    from_port   = 3031
    to_port     = 3031
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description = "agent socket"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"

  tags = "${merge(local.common_tags,
    map("Name" , "main"))}"
}

resource "aws_route_table" "r" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags = "${merge(local.common_tags,
    map("Name" , "main"))}"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = "${merge(local.common_tags,
    map("Name" , "main"))}"
  enable_dns_support = true
  enable_dns_hostnames = true
  assign_generated_ipv6_cidr_block = true
}

resource "aws_main_route_table_association" "a" {
  vpc_id         = "${aws_vpc.main.id}"
  route_table_id = "${aws_route_table.r.id}"
}

data "aws_canonical_user_id" "current" {}
locals {
  "account_name" = "${var.username}"
  "private_key" = "${file("${var.key_path}")}"
  common_tags = "${map(
    "CreatedBy", "${var.username}",
  )}"
}

resource "aws_subnet" "main" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.0.1.0/24"
  ipv6_cidr_block = "${cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, 1)}"
  assign_ipv6_address_on_creation = true

  tags = "${merge(local.common_tags,
    map("Name" , "main"))}"
}

data "template_file" "network_setup_script" {
  template = "${file("network_setup.sh")}"
}

resource "null_resource" "bootstrap_rabbitmq" {
  count = 3
  connection {
    host = "${aws_instance.rabbitmq.*.public_ip[count.index]}"
    type = "ssh"
    user = "centos"
    agent_identity = "${var.username}"
    private_key = "${local.private_key}"
  }
  provisioner "file" {
    content = "${data.template_file.network_setup_script.rendered}"
    destination = "/home/centos/network_setup.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "cd /home/centos",
      "sudo yum install -y epel-release",
      "sudo yum install -y jq",
      "echo IPv4 | sudo tee /etc/yum/vars/ip_resolve",
      "chmod +x /home/centos/network_setup.sh",
      "sudo /home/centos/network_setup.sh"
    ]
  }
}

resource "aws_instance" "rabbitmq" {
  count                       = 3
  ami                         = "${lookup(var.centos_amis, var.region)}"
  instance_type               = "m4.large"
  subnet_id                   = "${aws_subnet.main.id}"
  associate_public_ip_address = true
  key_name                    = "${var.username}"

  timeouts {
     create = "10m"
     delete = "10m"
  }
  tags = "${merge(local.common_tags,
    map(
    "Name" , "${var.username}.rabbitmq-${count.index}.sensu-ha",
    )
  )}"
  vpc_security_group_ids = ["${aws_security_group.poc.id}"]
}

resource "null_resource" "bootstrap_redis" {
  count = 2
  connection {
    host = "${aws_instance.redis.*.public_ip[count.index]}"
    type = "ssh"
    user = "centos"
    agent_identity = "${var.username}"
    private_key = "${local.private_key}"
  }
  provisioner "file" {
    content = "${data.template_file.network_setup_script.rendered}"
    destination = "/home/centos/network_setup.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "cd /home/centos",
      "sudo yum install -y epel-release",
      "sudo yum install -y jq",
      "echo IPv4 | sudo tee /etc/yum/vars/ip_resolve",
      "chmod +x /home/centos/network_setup.sh",
      "sudo /home/centos/network_setup.sh"
    ]
  }
}
resource "aws_instance" "redis" {
  count                       = 2
  ami                         = "${lookup(var.centos_amis, var.region)}"
  instance_type               = "m4.large"
  subnet_id                   = "${aws_subnet.main.id}"
  associate_public_ip_address = true
  key_name                    = "${var.username}"

  connection {
    type = "ssh"
    user = "centos"
    agent_identity = "${var.username}"
    private_key = "${local.private_key}"
  }

  tags = "${merge(local.common_tags,
    map(
    "Name" , "${var.username}.redis-${count.index}.sensu-ha",
    "AgentName" , "agent-${count.index}"
    )
  )}"
  timeouts {
     create = "10m"
     delete = "10m"
  }
  vpc_security_group_ids = ["${aws_security_group.poc.id}"]
}

output "rabbitmq_ips" {
  value = ["${aws_instance.rabbitmq.*.public_ip}"]
}

output "redis_ips" {
  value = ["${aws_instance.redis.*.public_ip}"]
}