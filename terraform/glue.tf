# Create a Glue job
resource "aws_glue_job" "glue_job" {
  name     = "my-glue-job"
  role_arn     = aws_iam_role.glue_job_role.arn
  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.replication.bucket}/scripts/my_glue_script.py"
    python_version  = "3"
  }
  max_capacity = 2
  glue_version = "3.0"
}

# Upload the PySpark script to the S3 bucket
resource "aws_s3_object" "glue_script" {
  bucket = aws_s3_bucket.replication.bucket
  key    = "scripts/my_glue_script.py"
  source = "../src/glue/my_glue_script.py"
}