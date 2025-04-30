variable "region" {
    description = "The AWS region"
    type        = string
    default     = "us-east-1"
  }

variable "nat_ami" {
  description = "NatInstance"
  default = "ami-0015c0130d6cc5da7"
}

variable "app_ami" {
  description = "Amazon Linux 2023 AMI for US East (N. Virginia)"
  default = "ami-0e449927258d45bc4"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "key_name" {
  default = "test"
}