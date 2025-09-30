# EKS Nodes Security Group
resource "aws_security_group" "node_sg" {
  name            = "${var.cluster_name}-node-sg"
  description     = "Security group for EKS nodes"
  vpc_id          = module.vpc.vpc_id
}

# Ingress: Allow HTTP traffic from alb
resource "aws_vpc_security_group_ingress_rule" "node_http_ingress" {
  security_group_id             = aws_security_group.node_sg.id
  description                   = "Allow HTTP traffic from alb"
  from_port                     = 80
  to_port                       = 80
  ip_protocol                   = "tcp"
  referenced_security_group_id  = aws_security_group.alb_sg.id # Allows traffic from alb
}

# Egress: Allow node to internet egress for updates
resource "aws_vpc_security_group_egress_rule" "node_https_egress" {
  security_group_id = aws_security_group.node_sg.id
  description       = "Allow node to internet egress for updates"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}



# ALB Security Group
resource "aws_security_group" "alb_sg" {
  name            = "${var.cluster_name}-alb-sg"
  description     = "Security group for alb"
  vpc_id          = module.vpc.vpc_id
}

# Ingress: Allow HTTPS from CloudFront, internet)
resource "aws_vpc_security_group_ingress_rule" "alb_https_ingress" {
  security_group_id = aws_security_group.alb_sg.id
  description       = "Allow inbound HTTPS from CloudFront/internet"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

# Egress: Allow HTTP traffic to EKS worker nodes
resource "aws_vpc_security_group_egress_rule" "alb_http_egress" {
  security_group_id            = aws_security_group.alb_sg.id
  description                  = "Allow HTTP traffic to worker nodes"
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
  referenced_security_group_id = aws_security_group.node_sg.id
}

# Egress: Allow return HTTPS (if ALB needs to talk to CloudFront/AWS services)
resource "aws_vpc_security_group_egress_rule" "alb_https_egress" {
  security_group_id = aws_security_group.alb_sg.id
  description       = "Allow HTTPS egress to internet (for CloudFront, ACM, health checks)"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}
