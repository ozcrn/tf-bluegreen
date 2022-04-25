data "aws_subnet_ids" "selected" {
    vpc_id = var.vpc_id
    filter {
        name = "tag:Name"
        values = [var.subnet_prefix]
    }
}

module "alb_sec_group" {
    source = "../aws-sec-group"
    name = "alb-security-group"
    description = "ALB security group"
    vpc_id = var.vpc_id
}
resource "aws_alb" "alb" {  
    name  = var.name
    subnets = data.aws_subnet_ids.selected.ids
    ip_address_type = "ipv4"
    security_groups = [module.alb_sec_group.security_group_id]

  tags = {    
    Name = var.name
  }   
}

resource "aws_acm_certificate" "cert" {
    domain_name = var.public_hostname
    subject_alternative_names = ["blue.${var.public_hostname}", "green.${var.public_hostname}"]
    validation_method = "DNS"

    lifecycle {
        create_before_destroy = true
    }
}

module "dns-cert-validation" {
    source = "../aws-r53"
    for_each = { for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => dvo }
    zone_id = var.dns_zone_id
    record_type = each.value.resource_record_type
    records = [each.value.resource_record_value]
    hostname = each.value.resource_record_name
}

resource "aws_alb_listener" "alb_listener_http" {  
    load_balancer_arn = resource.aws_alb.alb.arn
    port = 80
    protocol = "HTTP"
  
    default_action {
        type = "redirect"

        redirect {
            port        = "443"
            protocol    = "HTTPS"
            status_code = "HTTP_301"
        }
    }
}

resource "aws_alb_listener" "alb_listener_https" {  
    load_balancer_arn = resource.aws_alb.alb.arn
    port = 443
    protocol = "HTTPS"
    ssl_policy = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
    certificate_arn = resource.aws_acm_certificate.cert.arn
  
    default_action {
        type = "fixed-response"

        fixed_response {
            content_type = "text/plain"
            message_body = "Something went wrong"
            status_code  = "500"
        }
    }
}

resource "aws_alb_target_group" "target_group_blue" {  
    count = var.deploy_blue ? 1 : 0
    name     = "target-group-blue"  
    port     = "80"  
    protocol = "HTTP"  
    target_type = "instance"
    vpc_id   = var.vpc_id  
    tags = {    
        Name = "target-group-blue"
    }
}

resource "aws_lb_target_group_attachment" "target_group_attachment_blue" {
    for_each = var.deploy_blue == true ? var.blue_instances : tomap({})
    target_group_arn = resource.aws_alb_target_group.target_group_blue[0].id
    target_id = each.value
    port = 80
}

resource "aws_alb_listener_rule" "listener_rule_blue" {
    count = var.deploy_blue ? 1 : 0
    listener_arn = resource.aws_alb_listener.alb_listener_https.arn
    priority = 101
    action {    
        type             = "forward"    
        target_group_arn = resource.aws_alb_target_group.target_group_blue[0].id
    }   
    condition {
        host_header {
        values = ["blue.${var.public_hostname}"]
        }
    }
}

resource "aws_alb_target_group" "target_group_green" {  
    count = var.deploy_green ? 1 : 0
    name     = "target-group-green"  
    port     = "80"  
    protocol = "HTTP"  
    target_type = "instance"
    vpc_id   = var.vpc_id  
    tags = {    
        Name = "target-group-green"
    }
}

resource "aws_lb_target_group_attachment" "target_group_attachment_green" {
    for_each = var.deploy_green == true ? var.green_instances : {}
    target_group_arn = resource.aws_alb_target_group.target_group_green[0].id
    target_id = each.value
    port = 80
}

resource "aws_alb_listener_rule" "listener_rule_green" {
    count = var.deploy_green ? 1 : 0
    listener_arn = resource.aws_alb_listener.alb_listener_https.arn
    priority = 100
    action {    
        type             = "forward"    
        target_group_arn = resource.aws_alb_target_group.target_group_green[0].id
    }   
    condition {
        host_header {
        values = ["green.${var.public_hostname}"]
        }
    }
}

resource "aws_alb_listener_rule" "listener_rule_public" {
    count = var.active_environment == "blue" || var.active_environment == "green" ? 1 : 0
    listener_arn = resource.aws_alb_listener.alb_listener_https.arn
    priority = 10
    action {    
        type  = "forward"    
        target_group_arn = var.active_environment == "blue" ? resource.aws_alb_target_group.target_group_blue[0].id : resource.aws_alb_target_group.target_group_green[0].id
    }   
    condition {
        host_header {
        values = [var.public_hostname]
        }
    }
}

resource "aws_alb_listener_rule" "listener_rule_maintenance" {
    count = var.active_environment == "none" ? 1 : 0
    listener_arn = resource.aws_alb_listener.alb_listener_https.arn
    priority = 1
    action {
        type = "fixed-response"

        fixed_response {
            content_type = "text/html"
            message_body = "<!DOCTYPE html><html><body><h1>We're down for maintenance</h1></body></html>"
            status_code  = "503"
        }
    }  
    condition {
        host_header {
        values = [var.public_hostname]
        }
    }
}
