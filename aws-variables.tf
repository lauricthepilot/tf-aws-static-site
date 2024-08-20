variable "site_name" {
  description = "The name of the site."
  type        = string
  default     = "my-static-site"
}

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

variable "site_description" {
  description = "A description of the site."
  type        = string
  default     = "My Static Site"
}

variable "tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
  default     = {
    Module = "iac/modules/static_site"
    TagsUsed = "Module Default"
  }
}

variable "region" {
  description = "The AWS region to deploy to."
  type        = string
  default = "eu-west-1"
}

variable "error_page" {
  description = "filename of the error page"
  type = string
  default = "404.html"
}

variable "error_responses" {
  description = "A list of custom error responses for the CloudFront distribution."
  type        = list(object({
    error_code            = number
    response_code         = number
    response_page_path    = string
    error_caching_min_ttl = number
  }))
  default     = [
    {
      error_code            = 403
      response_code         = 404
      response_page_path    = "/404.html"
      error_caching_min_ttl = 3600
    }
  ]
}

variable "function_associations" {
  description = "A list of function associations for the CloudFront distribution."
  type        = list(object({
    event_type   = string
    function_arn = string
  }))
  default     = []
}

variable "geo_restrictions" {
  description = "A list of geo restrictions for the CloudFront distribution."
  type        = list(object({
    restriction_type = string
    locations        = list(string)
  }))
  default     = []
}