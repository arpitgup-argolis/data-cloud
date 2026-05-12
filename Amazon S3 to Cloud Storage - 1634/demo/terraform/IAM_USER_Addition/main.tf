terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}
variable "member_name" {}
variable "aws_group_name" {}

resource "aws_iam_user_group_membership" "add_user" {
  user = var.member_name
  groups = [
    var.aws_group_name
  ]
}