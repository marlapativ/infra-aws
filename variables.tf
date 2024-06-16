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

variable "eks_cluster" {
  type = object({
    name     = string
    version  = string
    ami_type = string
    node_groups = list(object({
      name           = string
      ami_type       = optional(string)
      instance_types = optional(list(string), ["c3.medium"])
      min_size       = optional(number, 3)
      max_size       = optional(number, 6)
      desired_size   = optional(number, 6)
    }))
  })
}
