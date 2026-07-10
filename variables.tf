variable "mongodb_user" {
  type        = string
  description = "Usuario administrador para MongoDB"
  default     = "unir_user"
}

variable "mongodb_password" {
  type        = string
  description = "Contraseña segura para la base de datos"
  sensitive   = true # Esto evita que la contraseña se imprima en las bitácoras o en la pantalla
}