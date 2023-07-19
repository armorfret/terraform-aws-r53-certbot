variable "admin_email" {
  description = "Email used for SOA record"
  type        = string
}

variable "cert_name" {
  description = "Certificate name"
  type        = string
}

variable "zone_id" {
  description = "Parent zone for delegation"
  type        = string
}

variable "issue_list" {
  description = "Allowed issuers for this certificate"
  type        = list(string)
  default     = ["letsencrypt.org; validationmethods=dns-01"]
}

variable "issuewild_list" {
  description = "Allowed issuers for this certificate"
  type        = list(string)
  default     = [";"]
}
