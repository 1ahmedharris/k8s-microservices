# v3


data "aws_availability_zones" "azs" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.0.0"
  name    = "eks-vpc"

  cidr            = var.vpc_cidr_block
  azs             = data.aws_availability_zones.azs.names[0:3]
  public_subnets  = var.public_subnet_cidr_blocks
  private_subnets = var.private_subnet_cidr_blocks

  enable_dns_hostnames = true
  enable_dns_support   = true
  
  enable_nat_gateway   = true
  single_nat_gateway   = true

  enable_dynamodb_endpoint = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}


# PUBLIC SUBNET NACL
resource "aws_network_acl" "public" {
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets

  # Ingress: Allow HTTP
  ingress {
    rule_no    = 100
    protocol   = 6
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  # Ingress: Allow HTTPS
  ingress {
    rule_no    = 110
    protocol   = 6
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # Ingress: Allow internal VPC TCP traffic
  ingress {
    rule_no    = 120
    protocol   = 6
    action     = "allow"
    cidr_block = var.vpc_cidr_block
    from_port  = 0
    to_port    = 65535
  }

  # Egress: Allow HTTP
  egress {
    rule_no    = 100
    protocol   = 6
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  # Egress: Allow HTTPS
  egress {
    rule_no    = 110
    protocol   = 6
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # Egress: Allow ephemeral ports for return traffic
  egress {
    rule_no    = 120
    protocol   = 6
    action     = "allow"
    cidr_block = var.vpc_cidr_block
    from_port  = 0
    to_port    = 65535

  tags = {
    Name = "public-nacl"
  }
}


# PRIVATE SUBNET NACL
resource "aws_network_acl" "private" {
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Ingress: Allow HTTP from VPC
  ingress {
    rule_no    = 100
    protocol   = 6
    action     = "allow"
    cidr_block = var.vpc_cidr_block
    from_port  = 80
    to_port    = 80
  }

  # Ingress: Allow HTTPS from VPC
  ingress {
    rule_no    = 110
    protocol   = 6
    action     = "allow"
    cidr_block = var.vpc_cidr_block
    from_port  = 443
    to_port    = 443
  }

  # Ingress: Allow ephemeral ports from VPC
  ingress {
    rule_no    = 120
    protocol   = 6
    action     = "allow"
    cidr_block = var.vpc_cidr_block
    from_port  = 1024
    to_port    = 65535
  }

  # Egress: Allow HTTP to anywhere
  egress {
    rule_no    = 100
    protocol   = 6
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  # Egress: Allow HTTPS to anywhere
  egress {
    rule_no    = 110
    protocol   = 6
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # Egress: Allow ephemeral ports for return traffic
  egress {
    rule_no    = 120
    protocol   = 6
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  tags = {
    Name = "private-nacl"
  }
}



