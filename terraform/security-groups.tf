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


resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.node_sg.id
  description       = "Allow HTTP traffic from alb"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "10.0.0.0/20" # Allows traffic from vpc
}



