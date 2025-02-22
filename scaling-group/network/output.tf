output "sg_allow_http" {
  value = aws_security_group.allow_http.id
}

output "sg_allow_ssh" {
  value = aws_security_group.allow_ssh.id
  
}

output "subnet_public_1" {
  value = aws_subnet.public_1
}

output "subnet_public_2" {
  value = aws_subnet.public_2
}

output "db_subnet_group" {
  value = aws_db_subnet_group.default.name
}

output "vpc_main" {
  value = aws_vpc.main
}