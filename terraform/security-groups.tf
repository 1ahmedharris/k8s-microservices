resource "aws_security_group" "eks_nodes" {
  name_prefix = "eks-nodes-"
  description = "EKS node security group"
  vpc_id      = module.vpc.vpc_id 

  # Ingress: Allow traffic from the EKS control plane
  ingress {
    from_port       = 9443 # Or whatever your specific control plane port is
    to_port         = 9443
    protocol        = "tcp"
    security_groups = [aws_eks_cluster.my_cluster.vpc_config.0.cluster_security_group_id]
  }

  # Ingress: Allow intra-cluster communication, node to node
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1" # All protocols
    self            = true
  }

  # Ingress: Allow inbound traffic from ALB on the application port
  # ALB sends unencrypted traffic to pods.
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Egress: Allow outbound traffic to the EKS control plane
  egress {
    from_port       = 9443 # Or your specific control plane port
    to_port         = 9443
    protocol        = "tcp"
    security_groups = [aws_eks_cluster.my_cluster.vpc_config.0.cluster_security_group_id]
  }

  # Egress: Allow outbound traffic to the internet via NAT Gateway for ECR
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # All protocols
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "alb" {
  name_prefix = "alb-"
  description = "ALB security group"
  vpc_id      = module.vpc.vpc_id

  # Ingress: Allow inbound HTTPS traffic from internet
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress: Allow outbound traffic to the EKS nodes on the application port
  egress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
  }
}


resource "aws_security_group" "dynamodb_endpoint" {
  name_prefix = "dynamodb-endpoint-"
  description = "Security Group for DynamoDB VPC Endpoint"
  vpc_id      = module.vpc.vpc_id

  # Ingress: Allow inbound traffic from EKS nodes
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
  }

  # Ingress rule for Lambda function to access the DynamoDB endpoint.
  
  ingress {
     from_port       = 443
     to_port         = 443
     protocol        = "tcp"
     security_groups = [aws_security_group.lambda.id]
  }

  # Egress: need default rule is often created to deny all egress???
}






# v2

# needed resources (placeholders):
# - module.vpc.vpc_id: ID of VPC.
# - aws_eks_cluster.my_cluster: EKS cluster resource.
# - var.lambda_security_group_id: ID Lambda function's security group.
# define in other Terraform files
# (e.g., vpc.tf, eks.tf) and are available as outputs or variables.

# security group for the EKS worker nodes. allows
# communication with the EKS control plane, the ALB, and other nodes,
# while restricting outbound access to necessary services.
#
module "eks_nodes_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.16.0" # Use a specific version for stability

  name        = "eks-nodes"
  description = "EKS worker node security group"
  vpc_id      = module.vpc.vpc_id

  # Ingress rules allow inbound traffic from specific sources.
  ingress_with_source_security_group_id = [
    # Rule 1: Allow inbound from the EKS control plane on port 443.
    # The EKS cluster's security group is automatically created and must be referenced.
    {
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      description              = "Allow EKS control plane to nodes"
      source_security_group_id = aws_eks_cluster.my_cluster.vpc_config[0].cluster_security_group_id
    },
    # Rule 2: Allow inbound from the ALB on the application's port (e.g., 80).
    # The `alb_sg` module output is used as the source.
    {
      from_port                = 80
      to_port                  = 80
      protocol                 = "tcp"
      description              = "Allow ALB to EKS nodes"
      source_security_group_id = module.alb_sg.security_group_id
    },
    # Rule 3: Allow inbound from other nodes in the same security group for intra-cluster communication.
    {
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1" # All protocols
      description              = "Allow intra-cluster communication"
      source_security_group_id = module.eks_nodes_sg.security_group_id
    },
  ]

  # Egress rules allow outbound traffic to specific destinations.
  egress_with_source_security_group_id = [
    # Rule 1: Allow outbound to the EKS control plane on port 443.
    {
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      description              = "Allow nodes to EKS control plane"
      source_security_group_id = aws_eks_cluster.my_cluster.vpc_config[0].cluster_security_group_id
    },
  ]

  # Egress rules with CIDR blocks for internet and VPC endpoint access.
  egress_rules = {
    # Rule 2: Allow outbound to the internet via NAT Gateway.
    # This is essential for pulling container images from ECR.
    all_outbound = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    },
    # Rule 3: Allow outbound to the DynamoDB VPC endpoint.
    # The endpoint is a gateway endpoint, so the destination is the VPC CIDR.
    dynamodb = {
      type        = "egress"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [module.vpc.vpc_cidr_block]
    },
  }
}

  
# Allows public internet traffic on HTTPS and forwards requests to the EKS nodes.
module "alb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.16.0"

  name        = "alb"
  description = "Application Load Balancer security group"
  vpc_id      = module.vpc.vpc_id

  # Ingress rule to allow inbound traffic from the internet on HTTPS port 443.
  ingress_rules = {
    public_https = {
      type        = "ingress"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow public inbound HTTPS"
    },
  }

  # Egress rule to allow outbound traffic to the EKS nodes on port 80.
  egress_with_source_security_group_id = [
    {
      from_port                = 80
      to_port                  = 80
      protocol                 = "tcp"
      description              = "Allow outbound to EKS nodes"
      source_security_group_id = module.eks_nodes_sg.security_group_id
    },
  ]
}

# Security group for the DynamoDB VPC Endpoint, 
# restricting access to only your EKS nodes and a hypothetical Lambda function.
module "dynamodb_endpoint_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.16.0"

  name        = "dynamodb-endpoint"
  description = "Security Group for DynamoDB VPC Endpoint"
  vpc_id      = module.vpc.vpc_id

  # Ingress rules to allow traffic from EKS nodes and Lambda function.
  ingress_with_source_security_group_id = [
    # Rule 1: Allow inbound from the EKS nodes on port 443.
    {
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      description              = "Allow EKS nodes to DynamoDB"
      source_security_group_id = module.eks_nodes_sg.security_group_id
    },
    # Rule 2 (Optional): Allow inbound from Lambda function's security group.
    # Uncomment and provide the variable for your Lambda's security group.
    # {
    #   from_port                = 443
    #   to_port                  = 443
    #   protocol                 = "tcp"
    #   description              = "Allow Lambda to DynamoDB"
    #   source_security_group_id = var.lambda_security_group_id
    # },
  ]
}
