variable "subnet_ids" {
  type        = set(string)
  description = "Subnet ids"
}

variable "aws_profile" {
  type        = string
  description = "AWS profile"
}