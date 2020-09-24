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

module "rds_cluster_aurora_mysql" {
  source          = "git::https://github.com/PicPay/module-terraform-rds-cluster.git?ref=master"
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