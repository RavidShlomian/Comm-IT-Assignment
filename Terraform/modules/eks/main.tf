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


data "tls_certificate" "example" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "example" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.example.certificates[0].sha1_fingerprint]
  url             = data.tls_certificate.example.url
}

# Create an IAM policy that allows access to ECR for pulling images
resource "aws_iam_policy" "keel_ecr_access_policy" {
  name        = "KeelECRAccessPolicy"
  description = "Policy for Keel to access ECR for pulling images"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Role that Keel will assume through the service account using OIDC
resource "aws_iam_role" "keel_ecr_access_role" {
  name = "KeelECRAccessRole"
  description = "IAM Role for Keel to access ECR using OIDC service account"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.example.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${data.tls_certificate.example.url}:sub" = "system:serviceaccount:nginx:keel-service-account"
          }
        }
      }
    ]
  })
}

# Attach the ECR access policy to the IAM role
resource "aws_iam_role_policy_attachment" "keel_ecr_policy_attachment" {
  role       = aws_iam_role.keel_ecr_access_role.name
  policy_arn = aws_iam_policy.keel_ecr_access_policy.arn
}

# Create the Kubernetes service account with the IAM role attached using annotations
resource "kubernetes_service_account" "keel_service_account" {
  metadata {
    name      = "keel-service-account"
    namespace = "nginx"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.keel_ecr_access_role.arn
    }
  }
}
