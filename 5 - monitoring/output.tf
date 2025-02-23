output "ami" {
  description = "AMI name"
  value       = data.aws_ami.amanzon_linux_2.name
}