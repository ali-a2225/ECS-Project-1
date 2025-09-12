# VPC with Public and Private Subnets, NAT Gateway, Internet Gateway, Route Tables, Security Groups




# Create VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  description = "main vpc"
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

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.gw]
  depends_on = [aws_subnet.public[*].id]
}





#Subnets
## Create Public subnets - eu-west-1a,1b,1c
resource "aws_subnet" "public" {
    count = 3
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.${count.index + 1}.0/24"
    region     = "eu-west-1"
    availability_zone = "eu-west-1${element(["a","b","c"], count.index)}"

  tags = {
    Name = "public_subnet_euwest-1${element(["a","b","c"], count.index)}"
  }
}

## Create Private subnets - eu-west-1a,1b,1c
resource "aws_subnet" "private" {
    count = 3
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1${count.index + 1}.0/24"
    region     = "eu-west-1"
    availability_zone = "eu-west-1${element(["a","b","c"], count.index)}"

  tags = {
    Name = "private_subnet_euwest-1${element(["a","b","c"], count.index)}"
  }
}









# Create Private Route Table
## Create one Private Route Table for each AZ
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






# Create Public Route Table
/*
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


#Associate Public subnet to Public route
resource "aws_route_table_association" "public" {
    count = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

*/





######################################

#Security Groups for Load Balancers and EC2 instances#
##Security Group: Allow HTTP and HTTPS from anywhere to Load Balancer


###Load Balancer Security Group
resource "aws_security_group" "lb_sg" {
  name        = "lb-sg"
  description = "Allow HTTP and HTTPS traffic"
  vpc_id      = aws_vpc.main.id

}




###Allow in HTTP from anywhere
resource "aws_vpc_security_group_ingress_rule" "sg_allow_http_from_0.0.0.0/0"{
  security_group_id = aws_security_group.lb_sg.id


  cidr_ipv4 = "0.0.0.0/0"
  from_port   = 80
  to_port     = 80
  ip_protocol    = "tcp"
  description = "Allow HTTP from anywhere"
}
###Allow in HTTPS from anywhere
resource "aws_vpc_security_group_ingress_rule" "sg_allow_https_from_0.0.0.0/0"{
  security_group_id = aws_security_group.lb_sg.id


  cidr_ipv4 = "0.0.0.0/0"
  from_port   = 443
  to_port     = 443
  ip_protocol    = "tcp"
  description = "Allow HTTPS from anywhere"
  
}


###Allow outbound traffic
resource "aws_vpc_security_group_egress_rule" "sg_allow_all_outbound" {
  security_group_id = aws_security_group.lb_sg.id

  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol    = "-1"
  description = "Allow all outbound traffic from Load Balancer"
}






###########################



##Security Group for EC2 instances to allow HTTP and HTTPS from Load Balancer only



###EC2 instances Security Group
resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow HTTP and HTTPS traffic"
  vpc_id      = aws_vpc.main.id

}

###Allow in HTTP from anywhere
resource "aws_vpc_security_group_ingress_rule" "sg_allow_http_from_lb"{
  security_group_id = aws_security_group.web_sg.id
  referenced_security_group_id = aws_security_group.lb_sg.id
  from_port   = 80
  to_port     = 80
  ip_protocol    = "tcp"
  description = "Allow HTTP traffic from Load Balancer"

}

###Allow in HTTP, and HTTPS from anywhere
resource "aws_vpc_security_group_ingress_rule" "sg_allow_https_from_lb"{
  security_group_id = aws_security_group.web_sg.id
  referenced_security_group_id = aws_security_group.lb_sg.id
  from_port   = 443
  to_port     = 443
  ip_protocol    = "tcp"
  description = "Allow HTTPS traffic from Load Balancer"

}



