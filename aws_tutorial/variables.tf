variable "amis" {
  type = map
  default = {
    "eu-west-1" = "ami-0aef57767f5404a3c"
 // "eu-west-2" = "ami-0aef57767f5404a3c"
  }
}

variable "region" {
}
variable "access_key" {}
variable "secret_key" {}
variable "instance_type" {
  default = "t2.micro"
}