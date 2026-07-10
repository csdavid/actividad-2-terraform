terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "network" {
  source = "./modules/network"
}

module "security" {
  source = "./modules/security"
  vpc_id = module.network.vpc_id
}

module "compute" {
  source            = "./modules/compute"
  public_subnet_id  = module.network.public_subnet_id
  private_subnet_id = module.network.private_subnet_id
  web_sg_id         = module.security.web_sg_id
  db_sg_id          = module.security.db_sg_id
  web_ami           = "ami-04a81a99f5ec58529" # Cambia por tu AMI de Packer si prefieres
  mongodb_user      = var.mongodb_user
  mongodb_password  = var.mongodb_password
}

# =================================================================
# EJERCICIO 2: CONFIGURACIÓN DEL APPLICATION LOAD BALANCER (ALB)
# =================================================================

# Creación del Balanceador de Carga
resource "aws_lb" "mean_alb" {
  name               = "mean-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.security.alb_sg_id]
  subnets            = [module.network.public_subnet_id, module.network.public_subnet_b_id]

  tags = {
    Name = "mean-stack-alb"
  }
}

# Creación del Grupo Destino (Target Group)
resource "aws_lb_target_group" "mean_tg" {
  name     = "mean-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.network.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = "80"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Creación del Listener para escuchar en el puerto 80
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.mean_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mean_tg.arn
  }
}

# Vinculación del Nodo Web al Target Group del Balanceador
resource "aws_lb_target_group_attachment" "web_attach" {
  target_group_arn = aws_lb_target_group.mean_tg.arn
  target_id        = module.compute.web_instance_id
  port             = 80
}