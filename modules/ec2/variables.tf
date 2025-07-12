variable "instance_name" {
  description = "Name tag for the EC2"
  type        = string
}
variable "instance_count" {
  description = "How many EC2 instances to create"
  type        = number
}

variable "subnet_id" {
  description = "The subnet to launch in"
  type        = string
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "public_key_path" {
  description = "Path to the SSH public key to import"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "volume_size" {
  description = "Root EBS volume size in GB"
  type        = number
}

variable "vpc_id" {
  description = "VPC ID to look up for SG"
  type        = string
}

variable "user_data" {
  description = "User data script for EC2 instance"
  type        = string
  default     = null
}