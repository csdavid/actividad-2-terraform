output "web_instance_id" { value = aws_instance.web_node.id }
output "web_public_ip"   { value = aws_instance.web_node.public_ip }
output "web_private_ip"  { value = aws_instance.web_node.private_ip }
output "db_private_ip"   { value = aws_instance.db_mongo.private_ip }
output "db_public_ip"    { value = aws_instance.db_mongo.public_ip }