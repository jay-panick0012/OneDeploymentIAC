###############################################################################
# AWS EKS Module – outputs.tf
###############################################################################

output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "Endpoint URL of the EKS API server."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_arn" {
  description = "ARN of the EKS cluster."
  value       = aws_eks_cluster.this.arn
}

output "cluster_ca_certificate" {
  description = "Base64-encoded certificate authority data for the cluster."
  value       = aws_eks_cluster.this.certificate_authority[0].data
  sensitive   = true
}

output "node_group_arn" {
  description = "ARN of the managed node group."
  value       = aws_eks_node_group.this.arn
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC identity provider (empty string when enable_oidc = false)."
  value       = var.enable_oidc ? aws_iam_openid_connect_provider.eks[0].arn : ""
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster control plane."
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "cluster_role_arn" {
  description = "ARN of the IAM role used by the EKS cluster."
  value       = aws_iam_role.cluster.arn
}

output "node_group_role_arn" {
  description = "ARN of the IAM role used by the node group."
  value       = aws_iam_role.node_group.arn
}
