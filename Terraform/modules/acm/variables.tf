variable "vpc_id" {
  description = "The VPC ID where the ALB should be deployed"
}

variable "public_subnets" {
  description = "List of public subnets for ALB"
}

variable "ec2_instance_id" {
  description = "The ID of the EC2 instance to attach to the target group (optional if using ECS/EKS)"
}
