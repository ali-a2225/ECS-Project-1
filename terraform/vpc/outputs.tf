output "vpc_id" {
    value = aws_vpc.main.id
    description = "VPC ID"
}

output "public_subnet_ids" {
    value = aws_subnet.public[*].id
    description = "Public Subnet IDs"
}

output "private_subnet_ids" {
    value = aws_subnet.private[*].id
    description = "Private Subnet IDs"
}

output "internet_gateway_id" {
    value = aws_internet_gateway.gw.id
    description = "Internet Gateway ID"
}