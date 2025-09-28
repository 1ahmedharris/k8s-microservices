# EKS Node Security Group
module "node_sg" {
  source          = "terraform-aws-modules/security-group/aws"
  version         = "~> 5.3.0"

  name            = "${var.cluster_name}-node-sg"
  description     = "Security group for EKS nodes"
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
