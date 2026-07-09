variable "vpc_id" { 
  type = string 
}

# SG para el Balanceador de Carga (Recibe tráfico del mundo)
resource "aws_security_group" "alb_sg" {
  name   = "mean-alb-sg"
  vpc_id = var.vpc_id

  ingress { 
    from_port   = 80 
    to_port     = 80 
    protocol    = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] 
  }

  egress { 
    from_port   = 0 
    to_port     = 0 
    protocol    = "-1" 
    cidr_blocks = ["0.0.0.0/0"] 
  }

  tags = { Name = "mean-alb-sg" }
}

# SG para el Nodo Web (Solo recibe tráfico desde el ALB)
resource "aws_security_group" "web_sg" {
  name   = "mean-web-sg"
  vpc_id = var.vpc_id

  ingress { 
    from_port       = 80 
    to_port         = 80 
    protocol        = "tcp" 
    security_groups = [aws_security_group.alb_sg.id] 
  }

  egress { 
    from_port   = 0 
    to_port     = 0 
    protocol    = "-1" 
    cidr_blocks = ["0.0.0.0/0"] 
  }

  tags = { Name = "mean-web-sg" }
}

# SG para MongoDB (Solo recibe tráfico desde el Nodo Web)
resource "aws_security_group" "db_sg" {
  name   = "mean-db-sg"
  vpc_id = var.vpc_id

  ingress { 
    from_port       = 27017 
    to_port         = 27017 
    protocol        = "tcp" 
    security_groups = [aws_security_group.web_sg.id] 
  }

  egress { 
    from_port   = 0 
    to_port     = 0 
    protocol    = "-1" 
    cidr_blocks = ["0.0.0.0/0"] 
  }

  tags = { Name = "mean-db-sg" }
}