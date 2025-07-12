/*output "public_ip" {
  value = aws_instance.this.public_ip
}

output "instance_id" {
  value = aws_instance.this.id
}
*/
output "public_ip" {
  value = [for instance in aws_instance.this : instance.public_ip]
}

output "instance_id" {
  value = [for instance in aws_instance.this : instance.id]
}