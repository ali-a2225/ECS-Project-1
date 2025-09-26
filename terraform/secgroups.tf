#Security Groups for Load Balancers and EC2 instances/ECS Tasks

##Security Group: Allow HTTP and HTTPS from anywhere to Load Balancer

###Load Balancer Security Group
resource "aws_security_group" "lb_sg" {
  name        = "lb-sg"
  description = "Allow HTTP and HTTPS traffic"
  vpc_id      = aws_vpc.main.id

}

###Allow in HTTP from anywhere
resource "aws_vpc_security_group_ingress_rule" "sg_allow_http_from_everywhere"{
  security_group_id = aws_security_group.lb_sg.id


  cidr_ipv4 = "0.0.0.0/0"
  from_port   = 80
  to_port     = 80
  ip_protocol    = "tcp"
  description = "Allow HTTP from anywhere"
}
###Allow in HTTPS from anywhere
resource "aws_vpc_security_group_ingress_rule" "sg_allow_https_from_everywhere"{
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


##Security Group for EC2 instances and ECS Tasks to allow HTTP and HTTPS from Load Balancer only

###EC2 instances Security Group
resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow HTTP and HTTPS traffic"
  vpc_id      = aws_vpc.main.id

}

###Allow in port 8080
resource "aws_vpc_security_group_ingress_rule" "allow_8080_from_lb"{
  security_group_id = aws_security_group.web_sg.id
  referenced_security_group_id = aws_security_group.lb_sg.id
  from_port   = 8080
  to_port     = 8080
  ip_protocol    = "tcp"
  description = "Allow 8080 traffic from Load Balancer"

}

###Allow outbound traffic from EC2 instances
resource "aws_vpc_security_group_egress_rule" "sg_allow_HTTPS_outbound_web" {
  security_group_id = aws_security_group.web_sg.id  
  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol = "-1"
  description = "Allow all outbound traffic from EC2 instances"
}