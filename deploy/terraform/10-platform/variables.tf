variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "europe-west1"
}

variable "my_ip_cidrs" {
  type = map(string)
}