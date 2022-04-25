bastion_ip = "x.x.x.x"
deploy_blue = false
deploy_green = false
active_environment = "none"

vpc_id = "vpc-xxxxxxxxxxxxxxxx"
dns_zone_id = "XXXXXXXXX"
public_hostname = "alb.example.com"

instances = [
    {
        name = "web-01"
        blue_ip = "10.255.2.50"
        green_ip = "10.255.2.51"
        instance_type = "t3.nano"
        subnet_name = "ai-private-az1"
        volume_size = 10
    },
    {
        name = "web-02"
        blue_ip = "10.255.2.150"
        green_ip = "10.255.2.151"
        instance_type = "t3.nano"
        subnet_name = "ai-private-az2"
        volume_size = 10
    }
]
