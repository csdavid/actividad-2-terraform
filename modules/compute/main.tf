# --- INSTANCIA DE BASE DE DATOS (MONGODB) ---
resource "aws_instance" "db_mongo" {
  ami                    = "ami-04a81a99f5ec58529" # Ubuntu 22.04 LTS
  instance_type          = "t3.micro"
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [var.db_sg_id]

  # Script automatizado de arranque para la Base de Datos
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install -y docker.io
              sudo systemctl start docker
              sudo systemctl enable docker
              
              # Levantar MongoDB oficial en el puerto standard exponiéndolo a la red privada
              sudo docker run -d --name social_events -p 27017:27017 \
                -e MONGO_INITDB_ROOT_USERNAME=${var.mongodb_user} \
                -e MONGO_INITDB_ROOT_PASSWORD=${var.mongodb_password} \
                mongo:latest
              EOF

  tags = { Name = "mean-mongodb-node" }
}

# --- INSTANCIA WEB (NGINX + NODE.JS BACKEND) ---
resource "aws_instance" "web_node" {
  ami                    = var.web_ami
  instance_type          = "t3.micro"
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [var.web_sg_id]
  associate_public_ip_address = true

  # Script automatizado para clonar y levantar el Frontend y Backend
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install -y docker.io docker-compose git
              sudo systemctl start docker
              sudo systemctl enable docker

              # NOTA: Reemplaza esta sección con el método para clonar tu código dentro de la máquina.
              # Como ejemplo, creamos una estructura idéntica a la tuya para levantar los contenedores de la app:
              mkdir -p /home/ubuntu/app
              cd /home/ubuntu/app

              # Aquí puedes clonar tu repositorio privado de Git o descargar tu código:
              git clone https://github.com/csdavid/unir-party.git .

              # Creamos un archivo docker-compose.yml optimizado en producción que apunta a la IP privada de Mongo
              cat <<'INNEREOF' > docker-compose.yml
              services:
                backend:
                  build: ./backend
                  ports:
                    - "3000:3000"
                  environment:
                    - MONGO_URI=mongodb://${aws_instance.db_mongo.private_ip}:27017/social_events?authSource=admin
                    - DB_USER=${var.mongodb_user}
                    - DB_PASSWORD=${var.mongodb_password}                    
                  restart: always

                frontend:
                  build: ./frontend
                  ports:
                    - "80:80"
                  restart: always
              INNEREOF

              # Nota: El docker-compose construirá tus Dockerfiles de Angular y Node de forma nativa
              # al vuelo dentro del servidor de AWS:
              sudo docker-compose up --build -d
              EOF

  tags = { Name = "mean-web-node" }
}