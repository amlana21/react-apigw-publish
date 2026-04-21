output app_sg_id {
  value = aws_security_group.app_sg.id
}

output web_sg_id {
  value = aws_security_group.web_sg.id
}

output "private_subnet_ids"{
    value = aws_subnet.app_private.*.id
}

output "apigw_private_subnet_ids" {
  value = [
    for s in aws_subnet.app_private :
    s.id if contains(data.aws_availability_zones.apigw_zones.names, s.availability_zone)
  ]
}

output app_svc_lb_tg_arn {
  value = aws_lb_target_group.app_svc_lb_tg.arn
}

output app_svc_dns {
  value = aws_lb.app_svc_lb.dns_name
}

output app_svc_alb_listener_arn {
  value = aws_lb_listener.app_svc_lb_listener.arn
}