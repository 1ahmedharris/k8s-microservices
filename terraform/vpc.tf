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
  
# These will be handled separately (do not include for now)
  #manage_default_route_table = false
  #create_igw                 = false
  #create_nat_gateway         = false
  #single_nat_gateway         = false
}


