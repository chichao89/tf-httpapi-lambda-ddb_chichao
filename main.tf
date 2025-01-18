data "aws_caller_identity" "current" {}

locals {
  name_prefix = split("/", "${data.aws_caller_identity.current.arn}")[1]
}

data "aws_route53_zone" "topmovies_zone" {
  name = "sctp-sandbox.com"
}