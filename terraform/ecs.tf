resource "aws_ecs_cluster" "cluster" {
  name = "streamlit-cluster"
}

resource "aws_ecs_task_definition" "streamlit_task" {
  family                   = "streamlit-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "4096"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name      = "streamlit-container"
    image     = "${aws_ecr_repository.streamlit_app.repository_url}:${var.image_version}"
    cpu       = 1024
    memory    = 4096
    essential = true
    portMappings = [
      {
        containerPort = 8501
        hostPort      = 8501
      },
    ]
  }])
}


resource "aws_ecs_service" "streamlit_service_with_lb" {
  name            = "streamlit-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.streamlit_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups   = [aws_security_group.sg.id]
    assign_public_ip  = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.tg.arn
    container_name   = "streamlit-container"
    container_port   = 8501
  }
}