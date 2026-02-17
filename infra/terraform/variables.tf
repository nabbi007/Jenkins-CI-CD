variable "region" {
  description = "AWS region to provision infrastructure in"
  type        = string
  default     = "eu-west-1"
}

variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
  default     = "jenkins-cicd-t3micro"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name for the EC2 key pair managed by Terraform"
  type        = string
  default     = "jenkins"
}

variable "ssh_cidr" {
  description = "CIDR block allowed to SSH into EC2"
  type        = string
  default     = "0.0.0.0/0"
}

variable "http_cidr" {
  description = "CIDR block allowed to access HTTP port 80"
  type        = string
  default     = "0.0.0.0/0"
}

variable "ecr_repository" {
  description = "ECR repository name used by the deployment"
  type        = string
  default     = "jenkins-ci-cd-demo"
}

variable "host_port" {
  description = "Host port used by the deployed container"
  type        = number
  default     = 80
}

variable "health_path" {
  description = "Health endpoint path used for deployment verification"
  type        = string
  default     = "/health"
}
