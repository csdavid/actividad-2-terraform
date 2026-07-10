resource "aws_vpc" "mean_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags                 = { Name = "mean-vpc" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.mean_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags                    = { Name = "mean-public-subnet" }
}

# Subred pública secundaria requerida por el Balanceador de Carga (ALB)
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.mean_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags                    = { Name = "mean-public-subnet-b" }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.mean_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"
  tags              = { Name = "mean-private-subnet" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.mean_vpc.id
}

# NAT Gateway para que MongoDB descargue paquetes de forma segura
resource "aws_eip" "nat_eip" { domain = "vpc" }

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id
}

# Tablas de ruteo
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.mean_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "mean-public-route-table"
  }
}

resource "aws_route_table_association" "pub_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "pub_b_assoc" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_rt.id
}

# modules/network/main.tf

# 1. Crear la Tabla de Ruteo Privada que apunta al NAT Gateway
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.mean_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id # El nombre de tu recurso NAT Gateway
  }

  tags = { Name = "mean-private-rt" }
}

# 2. Asociar la Subred Privada a esta nueva Tabla de Ruteo
resource "aws_route_table_association" "priv_assoc" {
  subnet_id      = aws_subnet.private.id # El nombre de tu subred privada
  route_table_id = aws_route_table.private_rt.id
}