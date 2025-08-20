# v4


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

  # 1.1 Ingress: Allow requests from clients/cloudfront to ALB
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # 1.5 Ingress: Allow incoming responses to clients   
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.vpc_cidr_block
    from_port  = 1024
    to_port    = 65535
  }

  # ADD 2.2 INGRESS FROM PRIVATE SUBNETS HEADED TO EGRESS/PUBLIC SUBNETS
  # ADD 2.3 EGRESS FOR API CALL FROM PUBLIC SUBNETS
  # Ingress: *2.4 Allow inbound responses from updates/api calls to aws services
  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # 2.2 Ingress: Allow updates/aws services api calls 
  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.vpc_cidr_block
    from_port  = 1024
    to_port    = 65535
  }

  # 1.2 Egress: Allow alb to pods 
  egress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.vpc_cidr_block
    from_port  = 80
    to_port    = 80
  }


  # 2.3 Egress: Allow updates/api calls to aws services 
  egress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # 1.6 Egress: Allow responses back to clients/cloudfront 
  egress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # 2.5 Egress: Allow responses from updates/api calls
  egress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "var.vpc_cidr_block"
    from_port  = 1024
    to_port    = 65535
  }



  tags = {
    Name = "public-nacl"
  }
}

# PRIVATE SUBNET NACL
resource "aws_network_acl" "private" {
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # 1.3 Ingress: Allow ALB to pods 
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.vpc_cidr_block
    from_port  = 80
    to_port    = 80
  }

  # 2.6 Ingress: Allow responses from updates/aws services  
  ingress {
    rule_no    = 130
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.vpc_cidr_block
    from_port  = 1024
    to_port    = 65535
  }

  # 3.2 Ingress: Allow return eks control plane/dynamodb traffic 
  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.vpc_cidr_block
    from_port  = 1024
    to_port    = 65535
  }

    ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.vpc_cidr_block
    from_port  = 10250
    to_port    = 10250
  }
  


  # 1.4 Egress: Allow pod responses to ALB/clients and port 10250
  egress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.vpc_cidr_block
    from_port  = 1024
    to_port    = 65535
  }

  # 3.1 Egress: Allow to EKS control plane/DynamoDB endpoints (HTTPS:443)
  egress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.vpc_cidr_block
    from_port  = 443
    to_port    = 443
  }

  # Egress: 2.1 Allow outbound traffic for external updates and api calls to AWS services 
  egress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"   
    from_port  = 443
    to_port    = 443
  }

  tags = {
    Name = "private-nacl"
  }
}













