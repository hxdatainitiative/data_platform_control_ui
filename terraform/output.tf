output "ecr_repository_url" {
  value = aws_ecr_repository.streamlit_app.repository_url
}

output "alb_dns_name" {
  value = aws_lb.example.dns_name
  description = "The DNS name of the application load balancer"
}