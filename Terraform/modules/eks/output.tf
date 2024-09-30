output "aws_eks_cluster_auth" {
    value = data.aws_eks_cluster_auth.main.id
}