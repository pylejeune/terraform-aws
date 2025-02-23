provider "aws" {
  region = "eu-west-3" # Changez la région si nécessaire
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # ID du propriétaire d'Ubuntu officiel

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

#generate random password
resource "random_password" "password" {
  length           = 24
  special          = true
  override_special = "!$%^*()-=+_?{}|"
}

#generate random username
resource "random_password" "username" {
  length           = 16
  special          = false
}

# username
resource "aws_ssm_parameter" "db_username" {
  name  = "db_username"
  type  = "SecureString"
  value = random_password.username.result
}

#password
resource "aws_ssm_parameter" "db_password" {
  name  = "db_password"
  type  = "SecureString"
  value = random_password.password.result
}


locals {
  username = aws_ssm_parameter.db_username.value
  password = aws_ssm_parameter.db_password.value
}

resource "aws_instance" "wordpress" {
  ami           = data.aws_ami.ubuntu.id # Ubuntu 20.04 LTS (Vérifiez pour votre région)
  instance_type = "t2.micro"
  #key_name      = "your-key-pair" # Remplacez par votre paire de clés
  security_groups = [aws_security_group.wordpress_sg.name]

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install -y apache2 mysql-server php php-mysql libapache2-mod-php wget unzip
              
              sudo systemctl start apache2
              sudo systemctl enable apache2
              
              sudo systemctl start mysql
              sudo systemctl enable mysql
              
              mysql -e "CREATE DATABASE wordpress;"
              mysql -e "CREATE USER '${local.username}'@'localhost' IDENTIFIED BY '${local.password}';"
              mysql -e "GRANT ALL PRIVILEGES ON wordpress.* TO '${local.username}'@'localhost';"
              mysql -e "FLUSH PRIVILEGES;"
              
              cd /tmp
              wget https://wordpress.org/latest.tar.gz
              tar -xvzf latest.tar.gz
              rm /var/www/html/index.html
              sudo mv wordpress/* /var/www/html/
              
              sudo chown -R www-data:www-data /var/www/html
              sudo chmod -R 755 /var/www/html
              
              sudo systemctl restart apache2
              EOF

  tags = {
    Name = "WordPress-Server"
  }
}

resource "aws_security_group" "wordpress_sg" {
  name        = "wordpress-sg"
  description = "Allow HTTP, HTTPS, and SSH"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["127.0.0.1/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
