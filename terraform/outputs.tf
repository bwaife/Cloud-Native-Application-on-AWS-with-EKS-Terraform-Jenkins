output "vpc_id" {
  value = aws_vpc.eks_vpc.id
}

output "cluster_name" {
  value = aws_eks_cluster.eks.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.eks.endpoint
}

output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}