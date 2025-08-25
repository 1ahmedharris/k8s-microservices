# EKS Managed Node Group Security Group
module "node_group_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.2.0"

  name        = "${var.cluster_name}-node-group-sg"
  description = "Security group for EKS managed node group"
  vpc_id      = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      description              = "Allow HTTP from ALB"
      from_port                = 80
      to_port                  = 80
      protocol                 = "tcp"
      source_security_group_id = module.alb_sg.security_group_id
    },
    {
      description              = "Allow HTTPS from EKS control plane"
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      source_security_group_id = module.cluster_sg.security_group_id
    },
    {
      description              = "Allow kubelet from EKS control plane"
      from_port                = 10250
      to_port                  = 10250
      protocol                 = "tcp"
      source_security_group_id = module.cluster_sg.security_group_id
    }
  ]

  egress_with_cidr_blocks = [
    {
      description = "Allow HTTP to ALB"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = module.alb_sg.security_group_id
    },
    {
      description = "Allow HTTPS to EKS control plane and DynamoDB endpoint"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = module.cluster_sg.security_group_id
    },
    {
      description = "Allow HTTPS to NAT Gateway for ECR/updates"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  tags = {
    Name = "${var.cluster_name}-node-group-sg"
  }
}

# ALB Security Group
module "alb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.2.0"

  name        = "${var.cluster_name}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      description = "Allow HTTPS from CloudFront"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  egress_with_source_security_group_id = [
    {
      description              = "Allow HTTP to EKS nodes"
      from_port                = 80
      to_port                  = 80
      protocol                 = "tcp"
      source_security_group_id = module.node_group_sg.security_group_id
    }
  ]

  tags = {
    Name = "${var.cluster_name}-alb-sg"
  }
}


# EKS Cluster Control Plane Security Group
module "cluster_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.2.0"

  name        = "${var.cluster_name}-cluster-sg"
  description = "Security group for EKS cluster control plane"
  vpc_id      = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      description              = "Allow HTTPS from EKS nodes"
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      source_security_group_id = module.node_group_sg.security_group_id
    }
  ]

  egress_with_source_security_group_id = [
    {
      description              = "Allow HTTPS to EKS nodes"
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      source_security_group_id = module.node_group_sg.security_group_id
    },
    {
      description              = "Allow kubelet to EKS nodes"
      from_port                = 10250
      to_port                  = 10250
      protocol                 = "tcp"
      source_security_group_id = module.node_group_sg.security_group_id
    }
  ]

  tags = {
    Name = "${var.cluster_name}-cluster-sg"
  }
}

# DynamoDB Gateway VPC Endpoint Security Group
module "dynamodb_endpoint_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.2.0"

  name        = "${var.cluster_name}-dynamodb-endpoint-sg"
  description = "Security group for DynamoDB Gateway VPC Endpoint"
  vpc_id      = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      description              = "Allow HTTPS from EKS nodes"
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      source_security_group_id = module.node_group_sg.security_group_id
    }
  ]

  egress_with_cidr_blocks = [
    {
      description = "Allow HTTPS to DynamoDB"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [var.vpc_cidr_block]
    }
  ]

  tags = {
    Name = "${var.cluster_name}-dynamodb-endpoint-sg"
  }
}
