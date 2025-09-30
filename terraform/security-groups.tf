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


resource "aws_vpc_security_group_ingress_rule" "allow_http_ingress" {
  security_group_id             = aws_security_group.node_sg.id
  description                   = "Allow HTTP traffic from alb"
  from_port                     = 80
  to_port                       = 80
  ip_protocol                   = "tcp"
  referenced_security_group_id  = aws_security_group.alb_sg.id # Allows traffic from alb
}

resource "aws_vpc_security_group_egress_rule" "allow_https_egress" {
  security_group_id = aws_security_group.node_sg.id
  description       = "Allow node to internet egress for updates"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}



