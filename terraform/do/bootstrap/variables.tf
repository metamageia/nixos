variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "pvt_key" {
  description = "Private SSH Key"
  type        = string
  sensitive   = true
}
