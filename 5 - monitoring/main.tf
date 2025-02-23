provider "aws" {
  region = "eu-west-3" # Choisissez la région AWS de votre choix
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "r" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.r.id
}

resource "aws_security_group" "web" {
  name        = "web_sg"
  description = "Allow HTTP and SSH traffic"
  vpc_id      = aws_vpc.main.id

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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "monitoring" {
  name        = "monitoring_sg"
  description = "Allow Prometheus, Grafana, and Node Exporter traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "amanzon_linux_2" {
  most_recent = true
  owners      = ["137112412989"] 

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

}

resource "aws_instance" "web" {
  ami                         = data.aws_ami.amanzon_linux_2.id # Amazon Linux 2 AMI (remplacez par l'AMI Alpine Linux si disponible)
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.main.id
  security_groups             = [aws_security_group.web.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello World from $(hostname -f)</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "WebServer"
  }
}

resource "aws_instance" "grafana" {
  ami                         = data.aws_ami.amanzon_linux_2.id # Amazon Linux 2 AMI (remplacez par l'AMI Alpine Linux si disponible)
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.main.id
  security_groups             = [aws_security_group.monitoring.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              systemctl start docker
              systemctl enable docker
              docker run -d -p 3000:3000 grafana/grafana
              EOF

  tags = {
    Name = "Grafana"
  }
}

resource "aws_instance" "prometheus" {
  ami                         = data.aws_ami.amanzon_linux_2.id # Amazon Linux 2 AMI (remplacez par l'AMI Alpine Linux si disponible)
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.main.id
  security_groups             = [aws_security_group.monitoring.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              systemctl start docker
              systemctl enable docker
              docker run -d -p 9090:9090 prom/prometheus
              EOF

  tags = {
    Name = "Prometheus"
  }
}

resource "aws_instance" "node_exporter" {
  ami                         = data.aws_ami.amanzon_linux_2.id # Amazon Linux 2 AMI (remplacez par l'AMI Alpine Linux si disponible)
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.main.id
  security_groups             = [aws_security_group.monitoring.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              systemctl start docker
              systemctl enable docker
              docker run -d -p 9100:9100 prom/node-exporter
              EOF

  tags = {
    Name = "NodeExporter"
  }
}

/*
resource "null_resource" "reload_prometheus" {
  triggers = {
    config_hash = filemd5("${path.module}/prometheus.yml") # Déclencheur basé sur le hash du fichier de configuration
  }

  provisioner "local-exec" {
    command = "sleep 120 && curl -X POST http://${aws_instance.prometheus.public_ip}:9090/-/reload"
  }
}
*/