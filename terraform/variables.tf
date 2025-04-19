variable "region" {
  default = "us-east-1"
}

variable "ami_id" {
  # Ubuntu 22.04 LTS (example)
  default = "ami-053b0d53c279acc90"
}

variable "instance_type" {
  default = "t3.large" # 2vCPU, 8GB
}

variable "key_name" {
  default = "ctse-key"
}

variable "public_key_path" {
  default = "~/.ssh/id_rsa.pub"
}
