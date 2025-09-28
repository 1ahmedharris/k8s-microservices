# EKS Managed Node Group Security Group
module "node_group_sg" {
  source          = "terraform-aws-modules/security-group/aws"
  version         = "~> 5.3.0"

  name            = "${var.cluster_name}-node-group-sg"
  description     = "Security group for EKS managed node group"
  vpc_id          = module.vpc.vpc_id
}


# ALB Security Group
module "alb_sg" {
  source          = "terraform-aws-modules/security-group/aws"
  version         = "~> 5.3.0"

  name            = "${var.cluster_name}-alb-sg"
  description     = "Security group for alb"
  vpc_id          = module.vpc.vpc_id
}


# Cluster Security Group
module "cluster_sg" {
  source          = "terraform-aws-modules/security-group/aws"
  version         = "~> 5.3.0"

  name            = "${var.cluster_name}-cluster-sg"
  description     = "Security group for cluster"
  vpc_id          = module.vpc.vpc_id
}

