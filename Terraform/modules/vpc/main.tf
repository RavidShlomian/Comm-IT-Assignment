#This fetches a list of availability zones from the region i am working in.
data "aws_availability_zones" "available" {}

resource "aws_vpc" "main" {
 cidr_block = "10.0.0.0/16"

 tags = {
   Name = "eks-vpc"
 }
}

resource "aws_subnet" "public_subnet" {
 count                   = 2
 vpc_id                  = aws_vpc.main.id
 cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
 availability_zone       = data.aws_availability_zones.available.names[count.index]
 map_public_ip_on_launch = true

 tags = {
   Name = "public-subnet-${count.index}"
 }
}

resource "aws_subnet" "private_subnet" {
 count                   = 2
 vpc_id                  = aws_vpc.main.id
 cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 2 ) # Private subnets start from a different netnum to avoid overlap
 availability_zone       = data.aws_availability_zones.available.names[count.index]
 map_public_ip_on_launch = true

 tags = {
   Name = "private-subnet-${count.index}"
 }
}
#public subnet
resource "aws_internet_gateway" "main" {
 vpc_id = aws_vpc.main.id
 tags = {
   Name = "main-igw"
 }
}

# Loop over the public subnets to create a NAT Gateway in each
resource "aws_nat_gateway" "nat" {
  count         = 2  
  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id     = aws_subnet.public_subnet[count.index].id
  
  tags = {
    Name = "nat-gateway-${count.index}"
  }
}

# Elastic IPs for the NAT Gateways
resource "aws_eip" "nat_eip" {
  count = 2  # Same count as NAT Gateways

  domain = "vpc"
}

#public subnet
resource "aws_route_table" "public" {
 vpc_id = aws_vpc.main.id
 count  = 2
 route {
   cidr_block = "0.0.0.0/0"
   gateway_id = aws_internet_gateway.main.id
 }

 tags = {
   Name = "public-route-table-${count.index}"
 }
}
#public subnet 
resource "aws_route_table_association" "a" {
 count          = 2
 subnet_id      = aws_subnet.public_subnet.*.id[count.index]
 route_table_id = aws_route_table.public[count.index].id
}

#private subnet
resource "aws_route_table" "private" {
 vpc_id = aws_vpc.main.id
 count  = 2
 route {
   cidr_block = "0.0.0.0/0"
   nat_gateway_id = aws_nat_gateway.nat[count.index].id 
   }

 tags = {
   Name = "private-route-table-${count.index}"
 }
}

#private subnet
resource "aws_route_table_association" "b" {
 count          = 2
 subnet_id      = aws_subnet.private_subnet.*.id[count.index]
 route_table_id = aws_route_table.private[count.index].id
}