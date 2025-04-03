provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
}

# Test VPC Infrastructure
resource "aws_vpc" "test_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "test-vpc"
  }
}

resource "aws_subnet" "test_subnets" {
  count = 2

  vpc_id            = aws_vpc.test_vpc.id
  cidr_block        = "10.0.${count.index}.0/24"
  availability_zone = "us-east-1${count.index == 0 ? "a" : "b"}"

  tags = {
    Name = "test-subnet-${count.index}"
  }
}

resource "aws_internet_gateway" "test_igw" {
  vpc_id = aws_vpc.test_vpc.id
  tags = {
    Name = "test-igw"
  }
}

resource "aws_route_table" "test_rt" {
  vpc_id = aws_vpc.test_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.test_igw.id
  }

  tags = {
    Name = "test-route-table"
  }
}

resource "aws_route_table_association" "test_rta" {
  count = 2

  subnet_id      = aws_subnet.test_subnets[count.index].id
  route_table_id = aws_route_table.test_rt.id
}

module "test_aurora" {
  source = "../../modules/aurora-serverless"

  name_prefix        = "test-aurora"
  aws_region         = "us-east-1"
  engine_name        = "aurora-mysql"
  database_name      = "testdb"
  master_username    = "admin"
  
  vpc_id             = aws_vpc.test_vpc.id
  subnet_ids         = aws_subnet.test_subnets[*].id
  allowed_cidr_blocks = [aws_vpc.test_vpc.cidr_block]
  
  auto_pause               = false
  skip_final_snapshot      = true
  max_capacity             = 8
  min_capacity             = 2
  storage_encrypted        = true
  kms_key_id               = null  # Uses default RDS KMS key
}

output "test_vpc_id" {
  value = aws_vpc.test_vpc.id
}

output "test_subnet_ids" {
  value = aws_subnet.test_subnets[*].id
}
