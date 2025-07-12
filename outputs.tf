output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = module.vpc.public_subnet_id
}

output "ec2_public_ips" {
  description = "Public IPs of all EC2 instances"
  value       = [ for inst in module.ec2[*] : inst.public_ip[0] ]
}

output "ec2_instance_ids" {
  description = "IDs of all EC2 instances"
  value       = [ for inst in module.ec2[*] : inst.instance_id[0] ]
}
