provider "aws" {
  region = "us-east-1"
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "vidly_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "vidly-vpc"
  }
}

resource "aws_subnet" "vidly_subnet" {
  count             = 2
  vpc_id            = aws_vpc.vidly_vpc.id
  cidr_block        = "10.0.${count.index}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "vidly-subnet-${count.index + 1}"
  }
}

resource "aws_internet_gateway" "vidly_igw" {
  vpc_id = aws_vpc.vidly_vpc.id

  tags = {
    Name = "vidly-igw"
  }
}

resource "aws_route_table" "vidly_rt" {
  vpc_id = aws_vpc.vidly_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vidly_igw.id
  }

  tags = {
    Name = "vidly-rt"
  }
}

resource "aws_route_table_association" "vidly_rta" {
  count          = 2
  subnet_id      = aws_subnet.vidly_subnet[count.index].id
  route_table_id = aws_route_table.vidly_rt.id
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "vidly-cluster"
  cluster_version = "1.27"

  vpc_id     = aws_vpc.vidly_vpc.id
  subnet_ids = aws_subnet.vidly_subnet[*].id

  eks_managed_node_groups = {
    default = {
      min_size     = 1
      max_size     = 3
      desired_size = 2

      instance_types = ["t3.medium"]
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

resource "aws_security_group" "mongodb_sg" {
  name        = "mongodb-sg"
  description = "Security group for MongoDB EC2 instance"
  vpc_id      = aws_vpc.vidly_vpc.id

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vidly_vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mongodb-sg"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "mongodb" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name      = "AKIAY6UYYAYYIP4R6VPF"  # Make sure to replace this with your actual key pair name

  vpc_security_group_ids = [aws_security_group.mongodb_sg.id]
  subnet_id              = aws_subnet.vidly_subnet[0].id

  tags = {
    Name = "vidly-mongodb"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y mongodb
              sudo systemctl start mongodb
              sudo systemctl enable mongodb
              EOF

  root_block_device {
    volume_type = "gp2"
    volume_size = 20
  }
}

output "mongodb_private_ip" {
  value = aws_instance.mongodb.private_ip
}