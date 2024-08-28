resource "aws_dynamodb_table" "example" {
  name           = "sample-dynamodb-table"
  billing_mode    = "PAY_PER_REQUEST"  # Use pay-as-you-go billing mode
  hash_key        = "PrimaryKey"

  attribute {
    name = "PrimaryKey"
    type = "S"
  }

  tags = {
    Name = "MyDynamoDBTable"
  }
}