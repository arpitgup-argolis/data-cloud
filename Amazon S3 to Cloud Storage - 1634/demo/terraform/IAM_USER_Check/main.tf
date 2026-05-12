terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}
variable "aws_group_name" {}

data "aws_iam_users" "check_user_if_exists" {}

data "aws_iam_group" "aws_group" {
  group_name = var.aws_group_name
}

#output from data source block for users in aws and members in aws group
output "user_in_aws" {
  value = data.aws_iam_users.check_user_if_exists.names
}
output "users_in_aws_group" {
  value = data.aws_iam_group.aws_group.users[*].user_name
}
