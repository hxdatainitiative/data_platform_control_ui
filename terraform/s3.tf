resource "aws_s3_bucket" "drop_zone" {
  bucket = "poc-ppa-streamlit-bucket-drop-zone"  # Asegúrate de que este nombre sea único a nivel global

  tags = {
    Name = "MyS3Bucket"
  }

  force_destroy = true
}

resource "aws_s3_bucket" "replication" {
  bucket = "poc-ppa-streamlit-bucket-replication"  # Asegúrate de que este nombre sea único a nivel global

  tags = {
    Name = "MyS3Bucket"
  }

  force_destroy = true
}

resource "aws_s3_bucket_versioning" "versioning_replication" {
  bucket = aws_s3_bucket.replication.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "versioning_drop_zone" {
  bucket = aws_s3_bucket.drop_zone.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "html_file" {
  bucket = aws_s3_bucket.replication.bucket
  key    = "html_reports/html_sample.html"
  source = "../src/html_sample.html"
}