#generate a random passowrd
resource "random_password" "password" {
  length           = 16 # Consider using a longer password for enhanced security
  special          = false
  override_special = "/@\" " # Exclude the disallowed characters
}

# create a key_management metadata for the RDS
resource "aws_kms_key" "default" {
  description             = "KMS key for RDS"
  deletion_window_in_days = 30 #default
  is_enabled              = true
  enable_key_rotation     = false

  tags = {
    Name = "aws_rds_secrets_manager"
  }
}

# generate secret key from aws key_management named as rds_admin
resource "aws_secretsmanager_secret" "rds_admin4" {
  name                    = "rds_admin4"
  kms_key_id              = aws_kms_key.default.key_id
  description             = "RDS admin password"
  recovery_window_in_days = 30 #default

  tags = {
    Name = "aws_rds_secrets_manager"
  }
}

# to manage AWS Secrets Manager secret value
resource "aws_secretsmanager_secret_version" "secret" {
  secret_id     = aws_secretsmanager_secret.rds_admin4.id
  secret_string = random_password.password.result
}