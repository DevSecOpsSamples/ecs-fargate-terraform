data "aws_availability_zones" "available" {
    state = "available"
}

resource "aws_vpc" "main" {
    cidr_block = "${local.ip_range}.0.0/16"
    enable_dns_support = true
    enable_dns_hostnames = true
    tags = {
        Name = "VPC for ${local.service_name}"
    }
}

resource "aws_subnet" "elasticache_subnet" {
    count = 2
    vpc_id     = aws_vpc.main.id
    cidr_block = "${local.ip_range}.${count.index + 41}.0/24"
    availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
    map_public_ip_on_launch = false
    tags = {
        Name = "${local.service_name} Cache Subnet Zone ${upper(substr(data.aws_availability_zones.available.names[count.index], -1, 1))}"
    }
}

resource "aws_subnet" "database_subnet" {
    count = 2
    vpc_id     = aws_vpc.main.id
    cidr_block = "${local.ip_range}.${count.index + 31}.0/24"
    availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
    map_public_ip_on_launch = false
    tags = {
        Name = "${local.service_name} Database Subnet Zone ${upper(substr(data.aws_availability_zones.available.names[count.index], -1, 1))}"
    }
}

resource "aws_subnet" "load_balancer_subnet" {
    count = 2
    vpc_id     = aws_vpc.main.id
    cidr_block = "${local.ip_range}.${count.index + 21}.0/24"
    availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
    map_public_ip_on_launch = false
    tags = {
        Name = "${local.service_name} LB Subnet Zone ${upper(substr(data.aws_availability_zones.available.names[count.index], -1, 1))}"
    }
}

resource "aws_subnet" "public_subnet" {
    count = 2
    vpc_id     = aws_vpc.main.id
    cidr_block = "${local.ip_range}.${count.index + 11}.0/24"
    availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
    map_public_ip_on_launch = false
    depends_on = [
        aws_internet_gateway.igw
    ]
    tags = {
        Name = "${local.service_name} Public Subnet Zone ${upper(substr(data.aws_availability_zones.available.names[count.index], -1, 1))}"
    }
}

resource "aws_subnet" "private_subnet" {
    count = 2
    vpc_id     = aws_vpc.main.id
    cidr_block = "${local.ip_range}.${(count.index + 1) * 64}.0/18"
    availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
    map_public_ip_on_launch = false
    tags = {
        Name = "${local.service_name} Private Subnet Zone ${upper(substr(data.aws_availability_zones.available.names[count.index], -1, 1))}"
    }
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main.id
}

resource "aws_eip" "nat_eip" {
    count = 2
    vpc = true
    lifecycle {
        create_before_destroy = true
    }
    tags = {
        Name = "${local.service_name}-eip-${count.index}"
    }
}

resource "aws_nat_gateway" "nat" {
    count = 2
    allocation_id = aws_eip.nat_eip[count.index].id
    subnet_id = aws_subnet.public_subnet[count.index].id
}

resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }

    tags = {
        Name = "${local.service_name}-public-route"
    }
}

resource "aws_route_table" "private" {
    count = 2
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat[count.index].id
    }

    tags = {
        Name = "${local.service_name}-private-route-${substr(data.aws_availability_zones.available.names[count.index], -1, 1)}"
    }
}

resource "aws_route_table_association" "public" {
    count = 2
    subnet_id = aws_subnet.public_subnet[count.index].id
    route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
    count = 2
    subnet_id = aws_subnet.private_subnet[count.index].id
    route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table_association" "load_balancer_route" {
    count = 2
    subnet_id = aws_subnet.load_balancer_subnet[count.index].id
    route_table_id = aws_route_table.public.id
}

## Development use only
resource "aws_route_table_association" "elasticache_route_table_dev" {
    count = 2
    subnet_id = aws_subnet.elasticache_subnet[count.index].id
    route_table_id = aws_route_table.public.id
}