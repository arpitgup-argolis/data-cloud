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

resource "aws_iam_user" "create_user" {
  name  = var.CE_User
  path          = "/"
  force_destroy = true
  tags = {
    vmdbm = "vm-migration-demo"
  }
}

resource "aws_iam_user_login_profile" "console_for_user" {
  user    = aws_iam_user.create_user.name
  password_reset_required = true
  depends_on = [aws_iam_user.create_user]
}

resource "aws_iam_access_key" "user_keys" {
  user = aws_iam_user.create_user.name
}

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
  secret_data = aws_iam_user.create_user.name
}

resource "google_secret_manager_secret_version" "password_secret_version" {
  secret = google_secret_manager_secret.AWS_Password.id
  secret_data = aws_iam_user_login_profile.console_for_user.password
}

resource "google_secret_manager_secret_version" "url_secret_version" {
  secret = google_secret_manager_secret.AWS_SignIN_URL.id
  secret_data = format("https://%s.signin.aws.amazon.com/console", trim("${aws_iam_user.create_user.arn}", "arn:aws:iam:::user/${var.CE_User}"))
}

# Secret for AWS Access Key ID
resource "google_secret_manager_secret" "AWS_Access_Key" {
  project   = var.project_id
  secret_id = "AWS_Access_Key_ID"
  replication { 
  auto {} 
  }
}

# Secret for AWS Secret Access Key
resource "google_secret_manager_secret" "AWS_Secret_Key" {
  project   = var.project_id
  secret_id = "AWS_Secret_Key"
  replication { 
  auto {}
  }
}

# Add the version for the Access Key ID
resource "google_secret_manager_secret_version" "access_key_version" {
  secret      = google_secret_manager_secret.AWS_Access_Key.id
  secret_data = aws_iam_access_key.user_keys.id
}

# Add the version for the Secret Access Key
resource "google_secret_manager_secret_version" "secret_key_version" {
  secret      = google_secret_manager_secret.AWS_Secret_Key.id
  secret_data = aws_iam_access_key.user_keys.secret
}
