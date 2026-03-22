output "alb_dns_name" {
  value       = aws_lb.shio_lb.dns_name
  description = "albのDNS名を返す"
}