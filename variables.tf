variable "admin_email" {
  description = "Email used for SOA record"
  type        = string
}

variable "delegation_set_id" {
  description = "Delegation set ID to reuse"
  type        = string
}

variable "subzone_name" {
  description = "Subdomain name for certificate validation zone"
  type        = string
}

variable "cert_name" {
  description = "Certificate name"
  type        = string
}

variable "parent_zone_id" {
  description = "Parent zone for delegation"
  type        = string
}

variable "caa_records" {
  description = "CAA records for certificate"
  type        = list(string)
  default     = []
}
