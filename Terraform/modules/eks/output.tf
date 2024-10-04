output "aws_eks_cluster_auth" {
    value = data.aws_eks_cluster_auth.main.id
}

output "eks_cluster_name" {
    value = aws_eks_cluster.main.id
}