variable "instance_type" {
  description = "Type of EC2 instance to provision"
  default     = "t3.nano"
}
variable = "ami_filter" {
  description = "Name filter and onwer for AMI"
  most_recent = true

  filter {
    name   = "name"
    values = ["bitnami-tomcat-*-x86_64-hvm-ebs-nami"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["979382823631"] # Bitnami
}

data "aws_vpc" "default" {
  default = true
}
module "blog_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "dev"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]



  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.app_ami.id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_blog_sg.security_group_id]

  subnet_id = module.blog_vpc.public_subnets[0]

  tags = {
    Name = "HelloWorld"
  }
}

module "autoscaling"
{
  source = "terrform-aws-modules/autoscaling/aws"
  version = "6.5.2"
  name = "blog"
  min_size = 1
  max_size = 2
  vpc_zone_identifier
}

module "alb" {
  source = "terraform-aws-modules/alb/aws"
  version = "~> 6.0"

  name    = "blog-alb"
  load_balancer_type = "application"
  vpc_id  = module.blog_vpc.vpc_id
  subnets = module.blog_vpc.public_subnets
Security_groups = module.blog_sg.security_group_id

  

  target_groups = {
    {
      name_prefix      = "blog"
      protocol         = "HTTP"
      port             = 80
      target_type      = "instance"
     
  }

]

http_tcp_listeners = {
  port = 80
  protocol = "http"
  target_group_index = 0
 }
}
  tags = {
    Environment = "Dev"

  }
}

module "security-group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.2.0"
  name = "blog_new"
  vpc_id = module.blog_vpc.vpc_id
  ingress_rules = ["http-80-tcp", "https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  egress_rules  = ["all-all"]
  egress_cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group" "blog" {
  name = "blog"
  description = "Allow http and https in Allow everything out"
  vpc_id = data.aws_vpc.default.id
}




resource "aws_security_group_rule" "blog_https_in"
{
  type       = "ingress"
  from_port  = 443
  to_port    = 443
  protocol   = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.blog.id
}
resource "aws_security_group_rule" "blog_everything_out"
{
  type       = "egress"
  from_port  = 0
  to_port    = 
  protocol   = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.blog.id
}
