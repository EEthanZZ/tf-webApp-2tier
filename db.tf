#assign an existing private subnet to the db
resource "aws_db_subnet_group" "db_subnet_group" {
  name        = "db_subnet_group"
  description = "db subnet group"
  subnet_ids  = [for subnet in aws_subnet.private_subnets : subnet.id]
}

#create a db
resource "aws_db_instance" "database" {
  allocated_storage      = 10
  db_name                = "mydb"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t3.micro"
  username               = "foo"
  password               = data.aws_secretsmanager_secret_version.secret.secret_string
  parameter_group_name   = "default.mysql5.7"
  skip_final_snapshot    = true
  storage_type           = "gp2"
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.id
  vpc_security_group_ids = [aws_security_group.db-sg.id]
}

# Retrieve metadata of the 'rds_admin' secret from AWS Secrets Manager to 
# access its ID, ensuring dependency on the secret's creation.
data "aws_secretsmanager_secret" "rds_admin4" {
  name       = "rds_admin4"
  depends_on = [aws_secretsmanager_secret.rds_admin4]
}
# Retrieve the current version of the 'rds_admin' secret from 
# AWS Secrets Manager to use the secret string as the database password
data "aws_secretsmanager_secret_version" "secret" {
  secret_id     = aws_secretsmanager_secret.rds_admin4.id
  version_stage = "AWSCURRENT" # Explicitly set this to AWSCURRENT
}

