variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
}

variable "key_pair_name" {
  description = "Name of an existing AWS key pair for SSH"
  type        = string
}

variable "instance_count" {
  description = "How many EC2 instances to create"
  type        = number
  
}
