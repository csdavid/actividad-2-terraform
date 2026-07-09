# =================================================================
# OUTPUTS DEL MÓDULO DE RED (modules/network/outputs.tf)
# =================================================================

output "vpc_id" {
  description = "El ID de la VPC principal creada para el Stack MEAN"
  value       = aws_vpc.mean_vpc.id
}

output "public_subnet_id" {
  description = "El ID de la subred publica principal (us-east-1a)"
  value       = aws_subnet.public.id
}

output "public_subnet_b_id" {
  description = "El ID de la subred publica secundaria requerida por el ALB (us-east-1b)"
  value       = aws_subnet.public_b.id
}

output "private_subnet_id" {
  description = "El ID de la subred privada donde se aloja MongoDB"
  value       = aws_subnet.private.id
}

output "nat_gateway_ip" {
  description = "La IP publica estatica (Elastic IP) asignada al NAT Gateway"
  value       = aws_eip.nat_eip.public_ip
}