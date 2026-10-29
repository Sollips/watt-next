# ── Ingestion component: log group, IAM role, permissions ─────────────
locals {
  ingest_function_name = "${local.name_prefix}-ingest" # → watt-next-dev-ingest (several locals blocks are allowed)
}

# Created by Terraform (not by Lambda), so retention is controlled: default = never expire → slow cost creep
resource "aws_cloudwatch_log_group" "ingest" {
  name              = "/aws/lambda/${local.ingest_function_name}" # the name Lambda writes to by default
  retention_in_days = 14
}

# Trust policy — WHO may assume the role: only the Lambda service
data "aws_iam_policy_document" "ingest_assume" {
  statement {
    actions = ["sts:AssumeRole"] # effect defaults to "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ingest" {
  name               = "${local.ingest_function_name}-role"
  description        = "Execution role for the eCO2mix ingestion Lambda"
  assume_role_policy = data.aws_iam_policy_document.ingest_assume.json
}

# Permissions — WHAT the role can do: the strict minimum
data "aws_iam_policy_document" "ingest_permissions" {
  statement {
    sid       = "WriteOwnLogs"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.ingest.arn}:*"] # streams in ITS OWN log group only
  }

  statement {
    sid       = "WriteRawEco2mix"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.datalake.arn}/raw/eco2mix/*"] # write-only, one prefix
  }
}

resource "aws_iam_role_policy" "ingest" {
  name   = "ingest-least-privilege"
  role   = aws_iam_role.ingest.id
  policy = data.aws_iam_policy_document.ingest_permissions.json
}