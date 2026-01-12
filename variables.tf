variable "project_name" {
  description = "Tag for project identification"
  type        = string
  default     = "tf-sample-ec2"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro" # change to t4g.micro for ARM
}

variable "ssh_ingress_cidr" {
  description = "CIDR allowed for SSH (22). For testing only; restrict in real use."
  type        = string
  default     = "0.0.0.0/0"
}

variable "key_pair_name" {
  description = "vm-keypair"
  type        = string
  default     = "tf-sample-key"
}

variable "public_key_openssh" {
  description = "Your SSH public key in OpenSSH format (e.g., contents of ~/.ssh/id_rsa.pub). If empty, key pair creation is skipped."
  type        = string
  default     = ""
}
