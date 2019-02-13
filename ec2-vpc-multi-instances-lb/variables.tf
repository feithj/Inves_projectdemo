# Region Credentials
variable "symphony_ip" {}
variable "secret_key" {}
variable "access_key" {}

# Main variables
variable "ami_image" {}
variable "ami_image_dot" {}
variable "ami_image_web" {}
variable "instance_number" {
  default = 1
}
variable "instance_number_dot" {
  default = 1
}
variable "instance_number_web" {
  default = 1
}
variable "instance_type" {
  default = "t2.micro"
}
variable "instance_type_dot" {
  default = "t2.micro"
}
variable "instance_type_web" {
  default = "t2.micro"
}
