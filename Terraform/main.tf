module "vpc" {
  source = "./modules/vpc"
}

module "iam" {
  source = "./modules/iam"
  eks_cluster_name = module.eks.eks_cluster_name
}

module "eks" {
  source           = "./modules/eks"
  eks_cluster_role = module.iam.eks_cluster_role
  eks_node_role    = module.iam.eks_node_role
  public_subnet    = module.vpc.public_subnet
  private_subnet   = module.vpc.private_subnet
}

module "ecr" {
  source = "./modules/ecr"
}