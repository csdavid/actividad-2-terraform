# --- INSTANCIA DE BASE DE DATOS (MONGODB) ---
resource "aws_instance" "db_mongo" {
  ami                    = "ami-04a81a99f5ec58529" # Ubuntu 22.04 LTS
  instance_type          = "t3.micro"
  # subnet_id              = var.private_subnet_id
  # vpc_security_group_ids = [var.db_sg_id]
  # --- ASIGNACIONES CORRECTAS Y OBLIGATORIAS ---
  subnet_id                   = var.public_subnet_id   # Forzamos subred PÚBLICA temporalmente
  vpc_security_group_ids      = [var.db_sg_id]          # ¡RECONECTAMOS EL SECURITY GROUP!
  associate_public_ip_address = true                    # Forzamos IP Pública
  key_name                    = "aws-practicas-unir"    # Tu llave SSH


user_data = <<-EOF
              #!/bin/bash
              # Pausa de seguridad de 15 segundos para asegurar que la interfaz de red en AWS esté 100% activa
              sleep 15

              sudo apt-get update -y
              sudo apt-get install -y docker.io
              sudo systemctl start docker
              sudo systemctl enable docker
              
              # Inicialización limpia de MongoDB oficial expuesto en el puerto estándar
              sudo docker run -d --name social_events -p 27017:27017 \
                -e MONGO_INITDB_ROOT_USERNAME=${var.mongodb_user} \
                -e MONGO_INITDB_ROOT_PASSWORD=${var.mongodb_password} \
                mongo:latest
              EOF

  tags = { Name = "mean-mongodb-node" }
}


# --- INSTANCIA WEB (NGINX + NODE.JS BACKEND) ---
resource "aws_instance" "web_node" {
  ami                         = var.web_ami
  instance_type               = "t3.micro"
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [var.web_sg_id]
  associate_public_ip_address = true
  key_name                    = "aws-practicas-unir"

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install -y docker.io docker-compose git
              sudo systemctl start docker
              sudo systemctl enable docker

              mkdir -p /home/ubuntu/app
              cd /home/ubuntu/app

              # Clonamos tu repositorio de manera directa al ser público
              git clone https://github.com/csdavid/unir-party.git .

              # Generamos el docker-compose.yml escapando el bloque de forma nativa para Terraform
              cat << 'DOCKEREOF' > docker-compose.yml
              version: '3.8'
              services:
                backend:
                  build: ./backend
                  ports:
                    - "3000:3000"
                  environment:
                    - MONGO_URI=mongodb_node:27017/social_events
                    - DB_USER=placeholder_user
                    - DB_PASSWORD=placeholder_pass
                  restart: always

                frontend:
                  build: ./frontend
                  ports:
                    - "80:80"
                  restart: always
              DOCKEREOF

              # MODIFICACIÓN TÉCNICA CLAVE: Inyectamos dinámicamente los valores reales calculados
              # por Terraform directo sobre las líneas del archivo usando sed. Evita cualquier error de escape.
              sed -i "s|mongodb_node|${aws_instance.db_mongo.private_ip}|g" docker-compose.yml
              sed -i "s|placeholder_user|${var.mongodb_user}|g" docker-compose.yml
              sed -i "s|placeholder_pass|${var.mongodb_password}|g" docker-compose.yml

              # Construimos de cero las imágenes locales y levantamos
              sudo docker-compose up --build -d
              EOF

  tags = { Name = "mean-web-node" }
}