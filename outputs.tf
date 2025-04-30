output "nat_instance_public_ip" {
  value = aws_instance.nat_instance.public_ip
}

output "load_balancer_dns_name" {
  value = aws_lb.app_lb.dns_name
}