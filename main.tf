terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    awscreds = {
      source  = "armorfret/awscreds"
      version = "~> 0.6"
    }
  }
}

locals {
  caa_records = flatten([
    "0 iodef \"mailto:${var.admin_email}\"",
    formatlist("0 issuewild \"%s\"", var.issuewild_list),
    formatlist("0 issue \"%s\"", var.issue_list),
  ])
}

#tfsec:ignore:aws-iam-no-policy-wildcards
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
    ]

    resources = [
      "arn:aws:route53:::hostedzone/${var.zone_id}",
    ]
  }

  statement {
    actions = [
      "route53:ChangeResourceRecordSets",
    ]

    resources = [
      "arn:aws:route53:::hostedzone/${var.zone_id}",
    ]

    condition {
      test     = "ForAllValues:StringEquals"
      variable = "route53:ChangeResourceRecordSetsNormalizedRecordNames"
      values   = ["_acme-challenge.${var.cert_name}"]
    }
  }
}

resource "aws_route53_record" "caa" {
  zone_id = var.zone_id
  name    = var.cert_name
  type    = "CAA"
  ttl     = "60"
  records = local.caa_records
}

resource "aws_iam_user_policy" "this" {
  name   = "certbot_${var.cert_name}"
  user   = aws_iam_user.this.name
  policy = data.aws_iam_policy_document.certbot_validation.json
}

resource "awscreds_iam_access_key" "this" {
  user = aws_iam_user.this.name
  file = "creds/${aws_iam_user.this.name}"
}

resource "aws_iam_user" "this" {
  name = "certbot_${var.cert_name}"
}

