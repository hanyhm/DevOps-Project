provider "aws" {
  region = "us-west-2"
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

  tags = {
    Name = "vidly-subnet-${count.index + 1}"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "vidly-cluster"
  cluster_version = "1.21"
  subnets         = aws_subnet.vidly_subnet[*].id
  vpc_id          = aws_vpc.vidly_vpc.id

  node_groups = {
    example = {
      desired_capacity = 2
      max_capacity     = 3
      min_capacity     = 1

      instance_type = "t2.medium"
    }
  }
}

resource "aws_security_group" "mongodb" {
  name        = "allow_mongodb"
  description = "Allow MongoDB inbound traffic"
  vpc_id      = aws_vpc.vidly_vpc.id

  ingress {
    description = "MongoDB from VPC"
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
}

resource "aws_db_instance" "mongodb" {
  identifier           = "vidly-mongodb"
  engine               = "mongodb"
  engine_version       = "4.0"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  storage_type         = "gp2"
  username             = "vidly_user"
  password             = "change_this_password"
  vpc_security_group_ids = [aws_security_group.mongodb.id]
  skip_final_snapshot  = true
}