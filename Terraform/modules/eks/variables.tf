variable "eks_cluster_role" {
  description = "eks_cluster_role for cluster permissions"
  type = string
}

variable "eks_node_role" {
  description = "eks_node_role for cluster node permissions"
  type = string
}

variable "public_subnet" {
    description = "public subnets for the eks cluster"
    type = list(string)
}

variable "private_subnet" {
    description = "private subnets for the eks cluster"
    type = list(string)
}