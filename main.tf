#=== data lookups ===
data "aws_ami" "amazon-linux" {
    most_recent = true
    owners = ["amazon"]
    filter {
        name = "name"
        values = ["amzn2-ami-hvm-*"]
    }
}
#=== /data lookups ===


module "alb" {
    source = "./modules/aws-alb"
#    count = var.deploy_blue || var.deploy_green ? 1 : 0
    name = "bluegreen-alb"
    deploy_blue = var.deploy_blue
    deploy_green = var.deploy_green
    active_environment = var.active_environment
    vpc_id = var.vpc_id
    subnet_prefix = "ai-public-*"
    blue_instances = tomap({for k, inst in module.instances-blue : k => inst.instance_id})
    green_instances = tomap({for k, inst in module.instances-green : k => inst.instance_id})
    public_hostname = var.public_hostname
    dns_zone_id = var.dns_zone_id

}


module "instances-blue" {
    source = "./modules/aws-instance"
    for_each = var.deploy_blue == true ? {for instance in var.instances:  instance.name => instance} : {}
    name = each.value["name"]
    ip_address = each.value["blue_ip"]
    ami = data.aws_ami.amazon-linux.id
    instance_type = each.value["instance_type"]
    vpc_security_group_ids = [module.instance-security-group[0].security_group_id]
    vpc_id = var.vpc_id
    subnet_name = each.value["subnet_name"]
    volume_size = each.value["volume_size"]
    environment = "blue"
    active_environment = var.active_environment
    bastion_ip = var.bastion_ip
}

module "instances-green" {
    source = "./modules/aws-instance"
    for_each = var.deploy_green == true ? {for instance in var.instances:  instance.name => instance} : {}
    name = each.value["name"]
    ip_address = each.value["green_ip"]
    ami = data.aws_ami.amazon-linux.id
    instance_type = each.value["instance_type"]
    vpc_security_group_ids = [module.instance-security-group[0].security_group_id]
    vpc_id = var.vpc_id
    subnet_name = each.value["subnet_name"]
    volume_size = each.value["volume_size"]
    environment = "green"
    active_environment = var.active_environment
    bastion_ip = var.bastion_ip
}

module "instance-security-group" {
    source = "./modules/aws-sec-group"
    count = var.deploy_blue || var.deploy_green ? 1 : 0
    name = "bluegreen-security-group"
    description = "Instance security group"
    vpc_id = var.vpc_id
}

module "dns-blue" {
    source = "./modules/aws-r53"
    count = var.deploy_blue ? 1 : 0
    zone_id = var.dns_zone_id
    record_type = "CNAME"
    records = [module.alb.cname]
    hostname = "blue.${var.public_hostname}"
}

module "dns-green" {
    source = "./modules/aws-r53"
    count = var.deploy_green ? 1 : 0
    zone_id = var.dns_zone_id
    record_type = "CNAME"
    records = [module.alb.cname]
    hostname = "green.${var.public_hostname}"
}

module "public-dns" {
    source = "./modules/aws-r53"
#    count = var.deploy_blue || var.deploy_green ? 1 : 0
    zone_id = var.dns_zone_id
    record_type = "CNAME"
    records = [module.alb.cname]
    hostname = var.public_hostname
}

