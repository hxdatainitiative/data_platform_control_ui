# Define the ECR repository
resource "aws_ecr_repository" "streamlit_app" {
  name = "streamlit-app"
  force_delete = true
}

# Use a timestamp data source to force the provisioner to run
resource "time_offset" "always_run" {
  offset_days  = 1 # This ensures the timestamp changes daily

}

# Define a null resource to build and push the Docker image
resource "null_resource" "docker_build_and_push" {
  triggers = {
    code_change = filesha256("../src/streamlit_app/app.py")
    version = var.image_version
  }

  provisioner "local-exec" {
    command = <<EOT
      # Authenticate Docker to ECR
      aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${aws_ecr_repository.streamlit_app.repository_url}

      # Build the Docker image
      docker build -t streamlit-app:${var.image_version} ../

      # Tag the Docker image for ECR
      docker tag streamlit-app:${var.image_version} ${aws_ecr_repository.streamlit_app.repository_url}:${var.image_version}

      # Push the Docker image to ECR
      docker push ${aws_ecr_repository.streamlit_app.repository_url}:${var.image_version}
    EOT

    environment = {
      AWS_PROFILE = "default"
    }
  }

  # Ensure this resource runs after ECR repository is created
  depends_on = [aws_ecr_repository.streamlit_app]
}