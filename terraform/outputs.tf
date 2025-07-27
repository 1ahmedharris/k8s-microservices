output "vpc_id" {
  description = "The ID of the deployed VPC."
  value       = module.my_vpc.vpc_id # Exposing output from official VPC module
}

output "eks_cluster_endpoint" {
  description = "The Kubernetes API endpoint of the EKS cluster."
  value       = module.eks.cluster_endpoint # Exposing output from official EKS module
}

output "eks_kubeconfig" {
  description = "The kubeconfig content for the EKS cluster."
  value       = module.eks.kubeconfig # Exposing output from official EKS module
  sensitive   = true # Mark sensitive outputs appropriately
}

output "lambda_function_arn" {
  description = "The ARN of the deployed Lambda function."
  value       = aws_lambda_function.my_function.arn # Exposing output from your custom Lambda resource
}

output "dynamodb_table_name_out" { # Use a different name if resource name conflicts
  description = "The name of the DynamoDB table."
  value       = aws_dynamodb_table.my_table.name # Exposing output from your custom DynamoDB resource
}
