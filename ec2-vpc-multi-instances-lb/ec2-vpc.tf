# Creating a VPC & Networking
resource "aws_vpc" "invesco_vpc" {
  cidr_block = "172.21.0.0/16"
  enable_dns_support = false

  tags {
    Name = "Invesco Demo VPC"
  }
}

resource "aws_vpc_dhcp_options" "dns_resolver" {
  domain_name_servers = ["8.8.8.8", "8.8.4.4","10.216.84.10" ]
  domain_name = "ivz.strato.net"

  tags {
    Name = "Invesco DHCP Options"
  }
}

resource "aws_vpc_dhcp_options_association" "dns_resolver" {
  vpc_id          = "${aws_vpc.invesco_vpc.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.dns_resolver.id}"
}

resource "aws_subnet" "invesco_subnet"{
    cidr_block = "172.21.1.0/24"
    vpc_id = "${aws_vpc.invesco_vpc.id}"
    tags {
      Name = "Invesco Demo Subnet"
    }

    # Makes sure DHCP configuration is absorbed in the subnet - Symphony specific
    depends_on = ["aws_vpc_dhcp_options_association.dns_resolver"]
}

resource "aws_internet_gateway" "invesco_gw" {
  vpc_id = "${aws_vpc.invesco_vpc.id}"
  tags {
    Name = "Invesco Internet Gateway"
  }
}

# The default route table will allow each subnet to route to the Internet Gateway
resource "aws_default_route_table" "default" {
    default_route_table_id = "${aws_vpc.invesco_vpc.default_route_table_id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.invesco_gw.id}"
    }
}


############ Instance Creation #############################

# Creating an instance
resource "aws_instance" "ivz_vm" {
    ami = "${var.ami_image}"
    instance_type = "${var.instance_type}"
    subnet_id = "${aws_subnet.invesco_subnet.id}"
    vpc_security_group_ids = ["${aws_security_group.allow_all.id}"]
    count = "${var.instance_number}"
    tags{
        Name="ivz_vm_${count.index}"
    }
}

# Creating an instance - DB Creation
resource "aws_instance" "ivz_vm_db" {
    ami = "${var.ami_image_dot}"
    instance_type = "${var.instance_type_dot}"
    subnet_id = "${aws_subnet.invesco_subnet.id}"
    vpc_security_group_ids = ["${aws_security_group.allow_all.id}"]
    count = "${var.instance_number_dot}"
    tags{
        Name="ivz_vm_db_${count.index}"
    }
}

# Creating an instance - Web Creation
resource "aws_instance" "ivz_vm_web" {
    ami = "${var.ami_image_web}"
    instance_type = "${var.instance_type_web}"
    subnet_id = "${aws_subnet.invesco_subnet.id}"
    vpc_security_group_ids = ["${aws_security_group.web-sec.id}", "${aws_security_group.allout.id}"]
    count = "${var.instance_number_web}"
    tags{
        Name="ivz_vm_web_${count.index}"
    }
}

### Creating Elastic IP for DOT server
resource "aws_eip" "ivz_vm_eip" {
  count = "${var.instance_number}"
  depends_on = ["aws_internet_gateway.invesco_gw"]
}

### Associating EIP to VM
resource "aws_eip_association" "invesco_eip_assoc" {
  count = "${var.instance_number}"
  instance_id = "${element(aws_instance.ivz_vm.*.id, count.index)}"
  allocation_id = "${element(aws_eip.ivz_vm_eip.*.id, count.index)}"
}

### Elastic IP for DB
resource "aws_eip" "ivz_vm_db_eip" {
  count = "${var.instance_number_dot}"
  depends_on = ["aws_internet_gateway.invesco_gw"]
}

### Assigning to DB
resource "aws_eip_association" "invesco_eip_db_assoc" {
  count = "${var.instance_number_dot}"
  instance_id = "${element(aws_instance.ivz_vm_db.*.id, count.index)}"
  allocation_id = "${element(aws_eip.ivz_vm_db_eip.*.id, count.index)}"
}


################## Security Group ##################

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all traffic"
  vpc_id      = "${aws_vpc.invesco_vpc.id}"

  ingress {
    protocol    = "tcp"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    protocol    = "udp"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "icmp"
    from_port   = 8 #ICMP type number if protocol is "icmp"
    to_port     = 0 #ICMP code number if protocol is "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol        = "-1"
    from_port       = 0
    to_port         = 0
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

################## WebServer Security Groups ##################

resource "aws_security_group" "web-sec" {
  name = "webserver-secgroup"
  vpc_id = "${aws_vpc.invesco_vpc.id}"

  # Internal HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  #ssh from anywhere (for debugging)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # ping access from anywhere
  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Public Access Security Group
# allow all egress traffic (needed for server to download packages)
resource "aws_security_group" "allout" {
  name = "allout-secgroup"
  vpc_id = "${aws_vpc.invesco_vpc.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# LB Sec group definition
resource "aws_security_group" "lb-sec" {
  name = "lb-secgroup"
  vpc_id = "${aws_vpc.invesco_vpc.id}"

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #ping from anywhere
  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
##################################


################ Load Balancer Build Out #####################


###### OLD CONFIG

# Create A LB Target Group
resource "aws_alb_target_group" "alb" {
  name = "alb"
  port = 80
  protocol = "HTTP"
  vpc_id = "${aws_vpc.invesco_vpc.id}"
}

# Assign Nodes to the Target Group
resource "aws_alb_target_group_attachment" "ivz_web_servers" {
  target_group_arn = "${aws_alb_target_group.alb.arn}"
  target_id       = "${element(aws_instance.ivz_vm_web.*.id,count.index)}"
  port             = 80
  count = "${var.instance_number_web}"
}

# To make LB internal (no floating IP) set internal to true
#resource "aws_alb" "ivz_lb" {
#  name = "ivz-web-lb"
#  internal = false
#  subnets = ["${aws_subnet.invesco_subnet.id}"]
#  security_groups = ["${aws_security_group.lb-sec.id}"]
#  load_balancer_type = "application"
#}

#resource "aws_alb_listener" "list" {
#  load_balancer_arn = "${aws_alb.ivz_lb.arn}"
#  port = 80
#  protocol = "HTTP"

#  "default_action" {
#    target_group_arn = "${aws_alb_target_group.alb.arn}"
#    type = "forward"
#  }
#}
