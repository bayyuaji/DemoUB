# Security groups
output "default security group demo id" {
  description = "The ID of the security group"
  value       = "${module.default-demo-sg.this_security_group_id}"
}

output "default security group demo name" {
  description = "The name of the security group"
  value       = "${module.default-demo-sg.this_security_group_name}"
}


