# EKS Nodes Security Group
resource "aws_security_group" "node_sg" {
  name            = "${var.cluster_name}-node-sg"
  description     = "Security group for EKS nodes"
  vpc_id          = module.vpc.vpc_id
}


# ALB Security Group
resource "aws_security_group" "alb_sg" {
  name            = "${var.cluster_name}-alb-sg"
  description     = "Security group for alb"
  vpc_id          = module.vpc.vpc_id
}
