terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }

    awscreds = {
      source  = "terraform.scrtybybscrty.org/armorfret/awscreds"
      version = "~> 0.3"
    }
  }
}

locals {
  default_caa_records = [
    "0 iodef \"mailto:${var.admin_email}\"",
    "0 issuewild \";\"",
    "0 issue \"letsencrypt.org\"",
  ]
  parsed_caa_records = coalescelist(var.caa_records, local.default_caa_records)
}

data "aws_iam_policy_document" "certbot_validation" {
  statement {
    actions = [
      "route53:ListHostedZones",
      "route53:ListHostedZonesByName",
      "route53:ListResourceRecordSets",
      "route53:GetChange",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    actions = [
      "route53:GetHostedZone",
      "route53:ListResourceRecordSets",
      "route53:ChangeResourceRecordSets",
    ]

    resources = [
      "arn:aws:route53:::hostedzone/${module.subzone.zone_id}",
    ]
  }
}

resource "aws_route53_delegation_set" "this" {
  reference_name = var.delegation_set_id
}

module "subzone" {
  source            = "armorfret/r53-zone/aws"
  version           = "0.4.0"
  admin_email       = var.admin_email
  domain_name       = var.subzone_name
  delegation_set_id = aws_route53_delegation_set.this.id
}

resource "aws_route53_record" "ns" {
  zone_id = var.parent_zone_id
  name    = var.subzone_name
  type    = "NS"
  ttl     = "60"
  records = aws_route53_delegation_set.this.name_servers
}

resource "aws_route53_record" "caa" {
  zone_id = var.parent_zone_id
  name    = var.cert_name
  type    = "CAA"
  ttl     = "60"
  records = local.parsed_caa_records
}

resource "aws_route53_record" "acme_cname" {
  zone_id = var.parent_zone_id
  name    = "_acme-challenge.${var.cert_name}"
  type    = "CNAME"
  ttl     = "60"
  records = ["_acme-challenge.${var.subzone_name}"]
}

resource "aws_iam_user_policy" "this" {
  name   = "certbot_${var.subzone_name}"
  user   = aws_iam_user.this.name
  policy = data.aws_iam_policy_document.certbot_validation.json
}

resource "awscreds_iam_access_key" "this" {
  user = aws_iam_user.this.name
  file = "creds/${aws_iam_user.this.name}"
}

resource "aws_iam_user" "this" {
  name = "certbot_${var.subzone_name}"
}

