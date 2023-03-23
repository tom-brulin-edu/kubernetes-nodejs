variable "environment_suffix" {
  type        = string
  default     = ""
  description = "Suffix to append to the environment name"
}

variable "location" {
  type        = string
  default     = "West Europe"
  description = "Location of the resources"
}

variable "project_name" {
  type        = string
  default     = "tbrulin"
  description = "Name of the project"
}

variable "webapp_port" {
  type        = number
  default     = 3000
  description = "Port of the webapp"
}

variable "default_email" {
  type        = string
  default     = "tom.brulin@viacesi.fr"
  description = "Default email for pgadmin"
}
