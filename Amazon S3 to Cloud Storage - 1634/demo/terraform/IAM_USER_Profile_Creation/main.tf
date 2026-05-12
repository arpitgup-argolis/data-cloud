terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}
#cerate variable for getting value

variable "CE_User" {}
variable "project_id" {}
variable "Access_Key" {
    sensitive   = true
}
variable "Secret_Key" {
    sensitive   = true
}

data "aws_iam_user" "fetch_user" {
  user_name = var.CE_User
}
resource "null_resource" "Install_AWS_CLI" {
  provisioner "local-exec" {
    
    interpreter = ["/bin/bash", "-c"]
    command = <<EOF
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install
    EOF
}
}
resource "null_resource" "Delete_Login_Profile" {
  provisioner "local-exec" {
    
    interpreter = ["/bin/bash", "-c"]
    command = <<EOF
    export AWS_ACCESS_KEY_ID="${var.Access_Key}"
    export AWS_SECRET_ACCESS_KEY="${var.Secret_Key}"
    export AWS_DEFAULT_REGION="us-east-1"
    aws configure
    output=$(aws iam get-login-profile --user-name ${var.CE_User} 2>/dev/null)
    if [ -z "$output" ]; then
        echo "User have no login profile"
    else
        aws iam delete-login-profile --user-name ${var.CE_User}
    fi
    EOF
}
depends_on = [null_resource.Install_AWS_CLI]
}
resource "aws_iam_user_login_profile" "console_for_user" {
  user    = var.CE_User
  password_reset_required = true
  depends_on = [null_resource.Delete_Login_Profile]
}


#loading user's aws data to users secret manager for later use
###########################################################
##loading user's aws data to users secret manager for later use
##Create secrets first
###########################################################

resource "google_secret_manager_secret" "AWS_Username" {
  project = var.project_id
  secret_id = "AWS_Username"
  replication {
    auto {}
  }
  depends_on = [aws_iam_user_login_profile.console_for_user]
}

resource "google_secret_manager_secret" "AWS_Password" {
  project = var.project_id
  secret_id = "AWS_Temp_Password"
  replication {
    auto {}
  }
  depends_on = [aws_iam_user_login_profile.console_for_user]
}

resource "google_secret_manager_secret" "AWS_SignIN_URL" {
  project = var.project_id
  secret_id = "AWS_SignIN_URL"
  replication {
    auto {}
  }
  depends_on = [aws_iam_user_login_profile.console_for_user]
}

# Add secret versions with known values
resource "google_secret_manager_secret_version" "user_secret_version" {
  secret = google_secret_manager_secret.AWS_Username.id
  secret_data = var.CE_User
}

resource "google_secret_manager_secret_version" "password_secret_version" {
  secret = google_secret_manager_secret.AWS_Password.id
  secret_data = aws_iam_user_login_profile.console_for_user.password
}

resource "google_secret_manager_secret_version" "url_secret_version" {
  secret = google_secret_manager_secret.AWS_SignIN_URL.id
  secret_data = format("https://%s.signin.aws.amazon.com/console", trim("${data.aws_iam_user.fetch_user.arn}", "arn:aws:iam:::user/${var.CE_User}"))
}