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

