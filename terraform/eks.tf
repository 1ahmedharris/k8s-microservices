module "eks_cluster" { 
  source              = "terraform-aws-modules/eks/aws"
  version             = "~> 21.1.0"  
  cluster_name        = "site-cluster" 
  kubernetes_version  = "1.33" 
  vpc_id              = module.vpc.vpc_id       
  subnet_ids          = module.vpc.private_subnets
  
  cluster_endpoint_private_access = true
  
  # --- EKS Managed Node Group Configuration ---
  # Define managed node groups here as a map.
  # The key (e.g., "resume-app-nodes") becomes the name of node group.
  managed_node_groups = {
    "spot-worker-nodes" = {
      # --- Instance Type Diversification (Most Important) ---
      # Provide a diverse list of suitable instance types for your workload.
      # AWS will pick from these based on the capacity-optimized strategy (default for Spot).
      instance_types = ["t3.micro", "t3a.micro", "t4g.micro", "t2.micro", "t3.small", "t3a.small"]

      # --- Spot Instance Configuration ---
      capacity_type = "SPOT" # Explicitly sets the node group to use Spot Instances

      # --- Scaling Configuration for Buffer ---
      # min_size: Ensures you always have at least this many nodes.
      # desired_size: Aims for this many nodes, providing a buffer.
      # max_size: The upper limit for scaling.
      min_size     = 2
      max_size     = 4
      desired_size = 3

      security_groups = [module.node_group_sg.security_group_id] # Associate node_group_sg
    

      # --- Node Role ARN (Optional, if managing IAM role externally) ---
      # If creating the IAM role for your EKS worker nodes outside this module
      # (as implied by your original `node_role_arn = aws_iam_role.resume_eks_node_role.arn`),
      # you would pass its ARN here.
      # If you omit this, the module will create and manage the node role for you (recommended).
      # node_role_arn = aws_iam_role.resume_eks_node_role.arn # Uncomment and use if applicable

      # --- AMI Type (Important for Graviton instances) ---
      # Set this based on the architecture of your primary instance types.
      # "AL2_ARM_64" for t4g instances, "AL2_x86_64" for Intel/AMD (t2, t3, t3a).
      # If you mix architectures, the module typically handles it, but specifying can be clearer.
      # ami_type = "AL2_x86_64" # Default for most Intel/AMD instances
      # ami_type = "AL2_ARM_64" # If t4g.micro is a significant part of your instance_types list

      # Optional: Disk size for the nodes (default is usually 20 GiB)
      # disk_size = 20
    }
  }
}







