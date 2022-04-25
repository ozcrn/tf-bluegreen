resource "aws_route53_record" "cname" {
  zone_id = var.zone_id
  name    = var.hostname
  type    = var.record_type
  ttl     = "300"
  records = var.records
}