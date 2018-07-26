provider "aws" {
	region = "ap-southeast-1"
  	access_key = "${var.aws_access_key}"
  	secret_key = "${var.aws_secret_key}"
}

resource "aws_key_pair" "develop1" {
        key_name   = "develop1"
        public_key = "${file("ssh-keys/develop1.pub")}"
}

module "default-demo-sg" {
  source =  "modules/aws-security-group"

  name        = "default demo sg"
  description = "default security group demo environment"
  vpc_id      = "vpc-bcc051db"

  egress_rules		   = ["all-all"]
  ingress_cidr_blocks      = ["10.0.0.0/16","175.103.43.136/29","158.140.185.100/30","175.103.36.160/30","202.4.189.16/30","52.76.67.91/32"]
  ingress_rules            = ["http-80-tcp","https-443-tcp","all-icmp"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 3306
      to_port     = 3307
      protocol    = "tcp"
      description = "Sample random security group ranges"
      cidr_blocks = "10.10.0.0/16"
    },
    {
      rule	  = "ssh-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}

### Step 2 ###

module "ec2_instance" {
  source = "modules/aws-ec2-instance"
 
  name			      = "demo"
  instance_count	      = 1
  ami                         = "ami-81cefcfd"
  instance_type               = "t2.nano"
  key_name                    = "develop1"
  monitoring                  = true
  vpc_security_group_ids      = ["sg-a778a4df"]
  subnet_id                   = "subnet-9f5b1ad6"
  associate_public_ip_address = true
  #user_data		      = "./provisioning/userdata.txt"
 
  root_block_device = [
    {
      volume_size = "15"
    }
  ]
 
  tags = {
    Environment	= "production"
    Group	= "sepulsa"
    CreateBy    = "terraform"
  }
}

### Step 3 ###

resource "null_resource" "this" {
  triggers {
    cluster_instance_ids = "${join("\n", module.ec2_instance.id)}"
  }

provisioner "local-exec" {
    working_dir = "./provisioning"
    command = "echo '[demoub:vars] \nansible_ssh_private_key_file = /home/ubuntu/.ssh/develop1.pem \n\n[demoub]' > ansible_hosts"
  }

provisioner "local-exec" {
    working_dir = "./provisioning"
    command = "echo '${join("\n", formatlist("demo ansible_host=%s ansible_port=22 ansible_user=ubuntu", module.ec2_instance.public_ip))}' >> ansible_hosts"
  }

provisioner "local-exec" {
    working_dir = "./provisioning"
    command = "echo \"PLEASE WAIT 60s\" && sleep 60 && sh ansible-deploy.sh"
  }
}

