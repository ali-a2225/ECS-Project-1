#EC2 instances in Public & Private Subnet and Security Group


# EC2 Instances in Public Subnet
resource "aws_instance" "web" {
    count         = 3
  ami           = "test" 
  instance_type = "test"
  subnet_id     = element(aws_subnet.public[*].id, count.index)
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  availability_zone = "eu-west-1${element(["a","b","c"], count.index)}"

  tags = {
    Name = "web-server-${count.index + 1}"
  }

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World from $(hostname -f)" > /usr/share/nginx/html/index.html
              yum install -y nginx
              systemctl start nginx
              systemctl enable nginx
              EOF
}





#Add EC2 instances to Target Group
aws_lb_target_group_attachment "web_tg_ec2" {
    count            = length(aws_instance.web)
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.web[count.index].id
  port             = 80
}

