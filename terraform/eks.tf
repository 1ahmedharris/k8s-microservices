module "eks_cluster" { 
  source              = "terraform-aws-modules/eks/aws"
  version             = "~> 21.1.0"   
  kubernetes_version  = "1.33" 
  cluster_name        = "site-cluster"
  vpc_id              = module.vpc.vpc_id       
  subnet_ids          = module.vpc.private_subnets
  
  cluster_endpoint_private_access = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
  }
  
  # --- EKS Managed Node Group Configuration ---
  # Define managed node groups here as a map.
  # The key (e.g., "resume-app-nodes") becomes the name of node group.

  eks_managed_node_groups = {
    "worker-nodes" = {
      instance_types  = ["t4g.small"]
      capacity_type   = "ON_DEMAND"
      ami_type        = "AL2_ARM_64"
      min_size        = 1
      max_size        = 2
      desired_size    = 1
      security_groups = [module.node_group_sg.security_group_id]
      # node_role_arn = aws_iam_role.resume_eks_node_role.arn 
    }
  }
}












