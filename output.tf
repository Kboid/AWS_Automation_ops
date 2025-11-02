output "nginx_url" {
  value = "http://${aws_instance.nginx_host.public_ip}"
}
