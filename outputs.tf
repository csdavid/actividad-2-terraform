output "ip_publica_nodo_web" { value = module.compute.web_public_ip }
output "ip_privada_nodo_web" { value = module.compute.web_private_ip }
output "ip_privada_nodo_mongodb" { value = module.compute.db_private_ip }
output "dns_del_balanceador" { value = aws_lb.mean_alb.dns_name }
output "ip_publica_nat_gateway" { value = module.network.nat_gateway_ip }