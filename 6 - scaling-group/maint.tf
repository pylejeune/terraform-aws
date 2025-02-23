provider "aws" {
  region = "eu-west-3"
}

module "network" {
  source = "./network"
}

/*
module "database" {
  source                 = "./database"
  vpc_security_group_ids = module.network.sg_allow_http
  db_subnet_group        = module.network.db_subnet_group
}
*/

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # ID du propriétaire d'Ubuntu officiel

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

####### Web AutoScaling ###########

resource "aws_launch_template" "web" {
  name_prefix   = "web-template-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t2.medium"

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [module.network.sg_allow_http, module.network.sg_allow_ssh]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install -y apache2 mysql-server php php-mysql libapache2-mod-php wget unzip
              
              sudo systemctl start apache2
              sudo systemctl enable apache2

              cd /tmp
              wget https://wordpress.org/latest.tar.gz
              tar -xvzf latest.tar.gz
              rm /var/www/html/index.html
              sudo mv wordpress/* /var/www/html/
              
              cat <<EOL > /var/www/html/healthcheck.php
              <?php
              http_response_code(200);
              echo "OK";
              ?>
              EOL
              
              sudo chown -R www-data:www-data /var/www/html
              sudo chmod -R 755 /var/www/html

              systemctl restart apache2              
              EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "web-instance"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_autoscaling_group" "web" {
  min_size                  = 1
  max_size                  = 4
  desired_capacity          = 2
  vpc_zone_identifier       = [module.network.subnet_public_1.id, module.network.subnet_public_2.id]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest" # Utilise la dernière version du Launch Template
  }

  tag {
    key                 = "Name"
    value               = "web-instance"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 180
  autoscaling_group_name = aws_autoscaling_group.web.name
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "high-cpu"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 30
  statistic           = "Average"
  threshold           = 40 # Seuil d'utilisation du CPU à 40%
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }
}

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "low-cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 30
  statistic           = "Average"
  threshold           = 40 # Seuil d'utilisation du CPU à 40%
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }
}

########### Load Balancer ##########

# Créer un load balancer
resource "aws_lb" "web" {
  name               = "web-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.network.sg_allow_http]
  subnets            = [module.network.subnet_public_1.id, module.network.subnet_public_2.id]

  tags = {
    Name = "web-lb"
  }
}

# Créer un groupe cible (target group) pour le load balancer
resource "aws_lb_target_group" "web" {
  name     = "web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.network.vpc_main.id

  health_check {
    path                = "/healthcheck.php"
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 10
    interval            = 60
    matcher             = "200"
  }
}

# Associer le groupe cible au load balancer
resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# Associer le groupe Auto Scaling au groupe cible
resource "aws_autoscaling_attachment" "web" {
  autoscaling_group_name = aws_autoscaling_group.web.name
  lb_target_group_arn    = aws_lb_target_group.web.arn
}



