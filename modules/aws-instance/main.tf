data "aws_subnet" "selected" {
    filter {
        name = "tag:Name"
        values = [var.subnet_name]
    }
    filter {
        name = "vpc-id"
        values = [var.vpc_id]
    }
}

locals {
    active-env-tag = var.environment == var.active_environment ? "true" : "false"
}

resource "aws_instance" "instance" {
    ami = var.ami
    instance_type = var.instance_type
    key_name = var.key_name
    vpc_security_group_ids = var.vpc_security_group_ids
    subnet_id = data.aws_subnet.selected.id
    private_ip = var.ip_address
    root_block_device {
        volume_size = var.volume_size
    }
    tags = {
        Name = "${var.environment}-${var.name}"
        Environment = var.environment
        "Active Environment" = local.active-env-tag
    }
    
    provisioner "remote-exec" {
        inline = ["echo Alive!"]

        connection {
            host        = self.private_ip
            type        = "ssh"
            user        = var.instance_username
            private_key = file("pem_files/${var.key_name}.pem")
            bastion_host = var.bastion_ip
            bastion_user = var.bastion_username
            bastion_private_key = file("pem_files/${var.key_name}.pem")
        }
    }

    provisioner "local-exec" {
        command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook --ssh-common-args='-o ProxyCommand=\"ssh -W %h:%p ${var.bastion_username}@${var.bastion_ip} -i pem_files/${var.key_name}.pem\"' -u ec2-user -i ${self.private_ip}, --private-key pem_files/${var.key_name}.pem playbooks/install-nginx.yml --extra-vars 'server_hostname=${self.tags["Name"]} bg_environment=${var.environment}'"
    }
  }