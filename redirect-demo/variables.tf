# map of akamai products, just to make life easy
variable "aka_products" {
  description = "map of akamai products"
  type        = map(string)

  default = {
    "ion" = "prd_Fresca"
    "dsa" = "prd_Site_Accel"
    "dd"  = "prd_Download_Delivery"
  }
}

# akamai product to use
variable "product_name" {
  description = "The Akamai delivery product name"
  type        = string
  default     = "ion"
}

# IPV4, IPV6_PERFORMANCE or IPV6_COMPLIANCE
variable "ip_behavior" {
  description = "use IPV4 to only use IPv4"
  type        = string
  default     = "IPV6_COMPLIANCE"
}

# FreeFlow=edgesuite.net, ESSL=egekey.net
variable "domain_suffix" {
  description = "edgehostname suffix"
  type        = string
  default     = "edgekey.net"
}

variable "group_name" {
  description = "Akamai group to use this resource in"
  type        = string
}

variable "email" {
  description = "Email address of users to inform when property gets created"
  type        = string
}

# this is our map with hostname being unique
variable "hostname_redirect" {
  description = "our list of redirects per hostname"
  type        = map(string)
}

variable "property_name" {
  description = "Name of the property but also for your edgehostname"
  type        = string
}

/* ariable "hostnames" {
  # first entry in list will also be property name
  # entry 0 will also be used to create edgehostname and will be name of property
  description = "One or more hostnames for a single property"
  type        = list(string)
} */

variable "policy_name" {
  description = "The Edge Redirector policy name"
  type        = string
}
