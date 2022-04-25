variable "deploy_blue" {
    type = bool
    default = false
}

variable "deploy_green" {
    type = bool
    default = false
}

variable "active_environment" {
    type = string
    default = "none"
    
    validation {
        condition = (
          var.active_environment == "blue" || var.active_environment == "green" || var.active_environment == "none"
        )
        error_message = "Variable active_environment must be either 'blue', 'green' or 'none'."
      }
}

variable "public_hostname" {
    type = string
}

variable "instances" {
    type = list
    default = []
}

variable "dns_zone_id" {
    type = string
}

variable "vpc_id" {
    type = string
}

variable "bastion_ip" {
    type = string
}