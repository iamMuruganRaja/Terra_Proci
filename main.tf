# Provider_block
provider "aws" {
    region = "ap-south-1"
  
}
#CIDR_Value
variable "cidr" {
    default = "10.0.0.0/16"  
}

#Key_Pair_to_connect_with_EC2Server

resource "aws_key_pair" "example" {
  key_name   = "terragodnow"  
  public_key = file("/home/ubuntu/.ssh/id_rsa.pub") 
}

#VPC
resource "aws_vpc" "myvpc" {
    cidr_block = var.cidr
  
}

#Subnet

resource "aws_subnet" "pubsub" {
     vpc_id                 = aws_vpc.myvpc.id
     availability_zone    = "ap-south-1a"
     map_public_ip_on_launch = true
     cidr_block = "10.0.0.0/24"

}

#internet_Gateway

resource "aws_internet_gateway" "myigw" {
    vpc_id = aws_vpc.myvpc.id
  
}

#Route_Table

resource "aws_route_table" "my" {
 vpc_id = aws_vpc.myvpc.id

 route{
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myigw.id
 } 
}

#Route_Table_Association

resource "aws_route_table_association" "rouass" {
    subnet_id = aws_subnet.pubsub.id
    route_table_id = aws_route_table.my.id
}

#security_group 

resource "aws_security_group" "mysec" {
    name = "mysec"
    vpc_id = aws_vpc.myvpc.id

    ingress {
        description = "http"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        }
    ingress {
        description = "ssh"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}


#server & provisioner

resource "aws_instance" "server" {
  ami                    = "ami-007020fd9c84e18c7"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.mysec.id]
  subnet_id              = aws_subnet.pubsub.id
  key_name               = aws_key_pair.example.key_name 

  # Specify connection details for SSH
  connection {
    type        = "ssh"
    user        = "ubuntu"  
    private_key = file("/home/ubuntu/.ssh/id_rsa") 
    host        = self.public_ip  
  }

  # File_provisioner_Config
  
  provisioner "file" {
    source      = "/home/ubuntu/app.py"  # Replace with the path to your local file
    destination = "/home/ubuntu/app.py"  # Replace with the path on the remote instance
  }

#Remote_Provisioner

  provisioner "remote-exec" {
    inline = [
      "echo 'Hello from the remote instance'",
      "sudo apt update -y",  # Update package lists (for ubuntu)
      "sudo apt-get install -y python3-pip",  # Example package installation
      "cd /home/ubuntu",
      "sudo pip3 install flask",
      "sudo python3 app.py &",
    ]
  }
}
