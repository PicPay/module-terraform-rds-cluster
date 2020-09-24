data "aws_vpc" "default" {
  filter {
    name = "tag:Name"
    values = ["VPC Default"]
  }
}

data "aws_subnet_ids" "database" {
  vpc_id = data.aws_vpc.default.id
  filter {
    name = "tag:Tier"
    values = ["database"]
  }
}

data "aws_security_group" "default" {
  vpc_id = data.aws_vpc.default.id
  name = "default"
}

data "aws_route53_zone" "internal" {
  name         = "lab.picpay.internal."
  private_zone = true
}

# create IAM role for monitoring
resource "aws_iam_role" "enhanced_monitoring" {
  name               = "rds-cluster-example-1"
  assume_role_policy = data.aws_iam_policy_document.enhanced_monitoring.json
}

# Attach Amazon's managed policy for RDS enhanced monitoring
resource "aws_iam_role_policy_attachment" "enhanced_monitoring" {
  role       = aws_iam_role.enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# allow rds to assume this role
data "aws_iam_policy_document" "enhanced_monitoring" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

module "rds_cluster_aurora_mysql" {
  source          = "git::https://github.com/PicPay/module-terraform-rds-cluster.git?ref=tags/0.1.0"
  engine          = "aurora"
  cluster_family  = "aurora-mysql5.7"
  cluster_size    = 2
  name            = "foo"
  squad           = "infracore"
  environment     = "lab"
  costcenter      = "1100"
  tribe           = "Infra Cloud"
  admin_user      = "admin1"
  admin_password  = "Test123456789"
  db_name         = "foobardb"
  instance_type   = "db.t2.small"
  vpc_id          = data.aws_vpc.default.id
  subnets         = data.aws_subnet_ids.database.ids
  security_groups = [data.aws_security_group.default.id]
  zone_id         = data.aws_route53_zone.internal.zone_id

  # enable monitoring every 30 seconds
  rds_monitoring_interval = 30

  # reference iam role created above
  rds_monitoring_role_arn = aws_iam_role.enhanced_monitoring.arn

  cluster_parameters = [
    {
      name  = "character_set_client"
      value = "utf8"
      apply_method = "pending-reboot"
    },
    {
      name  = "character_set_connection"
      value = "utf8"
      apply_method = "pending-reboot"
    },
    {
      name  = "character_set_database"
      value = "utf8"
      apply_method = "pending-reboot"
    },
    {
      name  = "character_set_results"
      value = "utf8"
      apply_method = "pending-reboot"
    },
    {
      name  = "character_set_server"
      value = "utf8"
      apply_method = "pending-reboot"
    },
    {
      name  = "collation_connection"
      value = "utf8_bin"
      apply_method = "pending-reboot"
    },
    {
      name  = "collation_server"
      value = "utf8_bin"
      apply_method = "pending-reboot"
    },
    {
      name         = "lower_case_table_names"
      value        = "1"
      apply_method = "pending-reboot"
    },
    {
      name         = "skip-character-set-client-handshake"
      value        = "1"
      apply_method = "pending-reboot"
    }
  ]
}