output "cname" {
    value = resource.aws_alb.alb.dns_name
}
