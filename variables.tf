# variable "aws_region" {
#   default     = "us-east-1"
#   description = "AWS Region"
#   type        = string
# }

variable "content_bucket_name" {
  default     = "prodwwwroot123456789"
  description = "bucket name should be uniq"
  type        = string
}

variable "log_bucket_name" {
  default     = "prodwwwlog123456789"
  description = "bucket name should be uniq"
  type        = string
}

variable "price_class" {
  description     = "https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PriceClass.html"
  type            = string
  validation {
    condition     = var.price_class == "PriceClass_100" || var.price_class == "PriceClass_200" || var.price_class == "PriceClass_All"
    error_message = "Price class could be only PriceClass_{100,200,All}."
  }
}

variable "tags" {
  default     = {Name = "lambda_rewrite_uri"}
  description = "Map of the tags for all resources"
  type        = map
}