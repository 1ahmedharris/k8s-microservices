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
    "kubernetes.io/role/elb"                  = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"         = "1"
  }

}




# -------------------------------------

# VVVVVVV 22222 ADDED NACL








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

# Public NACL for public subnets
resource "aws_network_acl" "public" {
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets

  ingress {
    rule_no    = 100
    protocol   = 6
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80    # HTTP
    to_port    = 80
  }

  ingress {
    rule_no    = 110
    protocol   = 6
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443   # HTTPS
    to_port    = 443
  }

  egress {
    rule_no    = 100
    protocol   = 6
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 65535
  }

  tags = {
    Name = "public-nacl"
  }
}

# Private NACL for private subnets (Lambda, worker nodes, EKS, etc.)
resource "aws_network_acl" "private" {
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  ingress {
    rule_no    = 100
    protocol   = 6
    action     = "allow"
    cidr_block = module.vpc.vpc_cidr_block
    from_port  = 0
    to_port    = 65535
  }

  egress {
    rule_no    = 100
    protocol   = 6
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 65535
  }

  tags = {
    Name = "private-nacl"
  }
}




resource "aws_network_acl" "eks_nacl" {
  vpc_id = aws_vpc.eks_vpc.id

  # Ingress Rules
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"  # Example: Allow all inbound TCP traffic
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # Egress Rules
  egress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"  # Example: Allow all outbound TCP traffic
    from_port  = 1024
    to_port    = 65535 # Ephemeral ports for outbound traffic
  }

  egress {
    protocol   = "-1" # All protocols
    rule_no    = 210
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "eks-cluster-nacl"
  }
}



