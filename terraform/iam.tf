resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn  = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = [
            "ecs-tasks.amazonaws.com",
            "s3.amazonaws.com",
            "batchoperations.s3.amazonaws.com"
            ]
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn  = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_policy" "ecs_task_policy" {
  name        = "EcsTaskPolicy"
  description = "Policy to allow ECS tasks to interact with DynamoDB and S3"

  # Define the policy JSON
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:BatchWriteItem"
        ],
        Effect   = "Allow",
        Resource = aws_dynamodb_table.example.arn
      },
      {
        "Effect": "Allow",
        "Action": [
          "s3:*"
        ],
        "Resource": [
          "${aws_s3_bucket.drop_zone.arn}",
          "${aws_s3_bucket.drop_zone.arn}/*",
          "${aws_s3_bucket.replication.arn}",
          "${aws_s3_bucket.replication.arn}/*"
        ]
      },
      {
        "Effect": "Allow",
        "Action": [
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeTasks",
          "ecs:ListTasks"
        ],
        "Resource": "*"
      },
      {
        Action = [
          "dynamodb:ListTables",
          "dynamodb:Scan",
          "dynamodb:Query"
        ],
        Effect   = "Allow",
        Resource = aws_dynamodb_table.example.arn
      },
      {
        "Effect":"Allow",
        "Action":[
          "iam:PassRole"
        ],
        "Resource":"arn:aws:iam::562178332708:role/ecs-task-role"
      },
      {
        "Effect":"Allow",
        "Action":[
          "glue:GetJobRuns"
        ],
        "Resource":"*"
      }
    ]
  })
}

# Attach the policy to the ECS task role
resource "aws_iam_role_policy_attachment" "ecs_task_policy_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn  = aws_iam_policy.ecs_task_policy.arn
}

# Define the Source Bucket Policy
resource "aws_s3_bucket_policy" "source_bucket_policy" {
  bucket = aws_s3_bucket.drop_zone.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = aws_iam_role.ecs_task_role.arn
        },
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:GetObjectVersion",
          "s3:GetObjectVersionTagging",
          "s3:GetObjectVersionAcl"          
        ],
        Resource = [
          aws_s3_bucket.drop_zone.arn,
          "${aws_s3_bucket.drop_zone.arn}/*"
        ]
      }
    ]
  })
}

# Define the Destination Bucket Policy
resource "aws_s3_bucket_policy" "destination_bucket_policy" {
  bucket = aws_s3_bucket.replication.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = aws_iam_role.ecs_task_role.arn
        },
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:PutObjectTagging",
          "s3:ListBucket"
        ],
        Resource = [
          aws_s3_bucket.replication.arn,
          "${aws_s3_bucket.replication.arn}/*"
        ]
      }
    ]
  })
}

# Create an IAM Role for the Glue job
resource "aws_iam_role" "glue_job_role" {
  name = "glue-job-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "glue.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach policies to the IAM Role
resource "aws_iam_role_policy_attachment" "glue_job_policy" {
  role       = aws_iam_role.glue_job_role.name
  policy_arn  = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# Attach policies to the IAM Role
resource "aws_iam_role_policy_attachment" "s3_policy" {
  role       = aws_iam_role.glue_job_role.name
  policy_arn  = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}