output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.react_app.id
}

output "public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_eip.react_app.public_ip
}

output "public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = aws_instance.react_app.public_dns
}

output "application_url" {
  description = "URL to access the React application"
  value       = "http://${aws_eip.react_app.public_ip}"
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh ubuntu@${aws_eip.react_app.public_ip}"
}

output "environment" {
  description = "Current workspace/environment"
  value       = local.workspace_name
}

output "deployment_status" {
  description = "Deployment status message"
  value       = "EC2 instance deployed. React app installation may take 3-5 minutes via user data script."
}