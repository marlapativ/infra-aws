variable "region" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "vpc_cidr_range" {
  type = string
}

variable "private_subnets" {
  type = list(object({
    name       = string
    cidr_range = string
    zone       = string
  }))
  default = []
}

variable "public_subnets" {
  type = list(object({
    name       = string
    cidr_range = string
    zone       = string
  }))
  default = []
}

variable "internet_gateway_name" {
  type = string
}

variable "route_table_name" {
  type = string
}

variable "route_cidr" {
  type = string
}

variable "network_acl_ingress" {
  type = list(object({
    protocol = string
    port     = number
    number   = number
    action   = string
    cidr     = string
  }))
}

variable "network_acl_egress" {
  type = list(object({
    protocol = string
    port     = number
    number   = number
    action   = string
    cidr     = string
  }))
}
