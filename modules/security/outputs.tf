output "alb_sg_id" {
  value       = aws_security_group.alb_sg.id
  description = "ID del Security Group del Balanceador de Carga"
}

output "web_sg_id" {
  value       = aws_security_group.web_sg.id
  description = "ID del Security Group del Nodo Web"
}

output "db_sg_id" {
  value       = aws_security_group.db_sg.id
  description = "ID del Security Group de la Base de Datos MongoDB"
}