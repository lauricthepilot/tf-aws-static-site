
variable "site_url" {
  description = "The URL of the site."
  type        = string
  default     = ""
}

variable "site_hosted_zone" {
  description = "The Route 53 hosted zone for the site."
  type        = string
  default     = ""
}

variable "tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
  default     = {
    Module = "iac/modules/static_site"
    TagsUsed = "Module Default"
  }
}
