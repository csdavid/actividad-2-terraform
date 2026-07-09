# Instancia para la aplicación Web (Node.js + Nginx) en la subred pública
resource "aws_instance" "web_node" {
  ami                    = var.web_ami
  instance_type          = "t3.micro"
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [var.web_sg_id]

  tags = { Name = "mean-web-node" }
}

# Instancia para la Base de Datos (MongoDB) en la subred privada
resource "aws_instance" "db_mongo" {
  ami                    = "ami-04a81a99f5ec58529" # Ubuntu 22.04 LTS Oficial para levantar MongoDB
  instance_type          = "t3.micro"
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [var.db_sg_id]

  tags = { Name = "mean-mongodb-node" }
}