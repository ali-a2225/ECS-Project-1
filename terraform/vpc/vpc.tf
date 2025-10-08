# VPC with Public and Private Subnets, NAT Gateway, Internet Gateway and Route Tables

# Create VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main-vpc"
  }
}

# Create IGW
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

# Create EIP for NAT Gateway
resource "aws_eip" "NAT" {
    count = length(aws_subnet.public)
  domain   = "vpc"
  depends_on = [aws_internet_gateway.gw]
}


# Create NAT Gateway
resource "aws_nat_gateway" "NAT" {
    count = length(aws_subnet.public)
  allocation_id = aws_eip.NAT[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "gw-NAT-${element(["a", "b", "c"], count.index)}"
  }
}


#Subnets
## Public Subnet
### Create Public subnets - eu-west-2a,2b,2c
resource "aws_subnet" "public" {
    count = 3
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.${count.index + 1}.0/24"
    region     = "eu-west-2"
    availability_zone = "eu-west-2${element(["a","b","c"], count.index)}"

  tags = {
    Name = "public_subnet_euwest-2${element(["a","b","c"], count.index)}"
  }
}

### Create Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

###Associate Public subnet to Public route
resource "aws_route_table_association" "public" {
    count = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}


##Private Subnet
### Create Private subnets - eu-west-2a,b,c
resource "aws_subnet" "private" {
    count = 3
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1${count.index + 1}.0/24"
    region     = "eu-west-2"
    availability_zone = "eu-west-2${element(["a","b","c"], count.index)}"

  tags = {
    Name = "private_subnet_euwest-2${element(["a","b","c"], count.index)}"
  }
}

### Create Private Route Table (1 per AZ)
resource "aws_route_table" "private" {
    count = length(aws_subnet.public)
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.NAT[count.index].id
  }
  tags = {
    Name = "private-route-table-${element(["a", "b", "c"], count.index)}"
  }
}

#Associate Private subnet to Private route
resource "aws_route_table_association" "private" {
    count = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
