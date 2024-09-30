resource "aws_eks_cluster" "main" {
 name     = "main-eks-cluster"
 role_arn = var.eks_cluster_role

 vpc_config {
   subnet_ids = concat(var.public_subnet, var.private_subnet) #concatenating multiple lists together
 }

 tags = {
   Name = "main-eks-cluster"
 }
}

resource "aws_eks_node_group" "main" {
 cluster_name    = aws_eks_cluster.main.name
 node_group_name = "main-eks-node-group"
 node_role_arn   = var.eks_node_role
 subnet_ids      = var.private_subnet
 remote_access {
   ec2_ssh_key     = "moveo-key"

 }
 scaling_config {
   desired_size = 2
   max_size     = 3
   min_size     = 1
 }

 tags = {
   Name = "main-eks-node-group"
 }
}

data "aws_eks_cluster_auth" "main" {
  name = aws_eks_cluster.main.name
}

provider "kubernetes" {
  host  = aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
  token = data.aws_eks_cluster_auth.main.token
}

resource "helm_release" "argocd" {
 depends_on = [aws_eks_node_group.main]
 name       = "argocd"
 repository = "https://argoproj.github.io/argo-helm"
 chart      = "argo-cd"
 version    = "4.5.2"

 namespace = "argocd"

 create_namespace = true

 set {
   name  = "server.service.type"
   value = "LoadBalancer"
 }

 set {
   name  = "server.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
   value = "nlb"
 }
}


data "kubernetes_service" "argocd_server" {
 metadata {
   name      = "argocd-server"
   namespace = helm_release.argocd.namespace
 }
}
