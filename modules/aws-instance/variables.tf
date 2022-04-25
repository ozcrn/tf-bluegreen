variable "name" {
    type = string
}

variable "ami" {
    type = string
}

variable "instance_type" {
    type = string
}

variable "key_name" {
    type = string
    default = "terraform"
}

variable "vpc_security_group_ids" {
    type = list(string)
}

variable "subnet_name" {
    type = string
}

variable "volume_size" {
    type = number
    default = 10
}

variable "environment" {
    type = string
}

variable "active_environment" {
    type = string
}

variable "ip_address" {
    type = string
}

variable "vpc_id" {
    type = string
}

variable "instance_username" {
    type = string
    default = "ec2-user"
}

variable "bastion_username" {
    type = string
    default = "ec2-user"
}

variable "bastion_ip" {
    type = string
}