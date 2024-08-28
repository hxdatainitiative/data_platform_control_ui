# Create public subnets
# resource "aws_subnet" "public_subnets" {
#   count = 2  # Adjust this as needed

#   vpc_id                  = aws_vpc.main.id
#   cidr_block              = element(["10.0.1.0/24", "10.0.2.0/24"], count.index)
#   availability_zone       = element(data.aws_availability_zones.available.names, count.index)
#   map_public_ip_on_launch = true

#   tags = {
#     Name = "public-subnet-${count.index + 1}"
#   }
# }

# Data source to get availability zones
data "aws_availability_zones" "available" {}

