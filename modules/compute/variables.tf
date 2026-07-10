variable "public_subnet_id"  { type = string }
variable "private_subnet_id" { type = string }
variable "web_sg_id"         { type = string }
variable "db_sg_id"          { type = string }
variable "web_ami"           { type = string }
variable "mongodb_user"      { type = string }
variable "mongodb_password"  { type = string }