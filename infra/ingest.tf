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

  statement {
    sid       = "SendFailuresToDlq"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.ingest_dlq.arn] # only this one queue
  }

  statement {
    sid       = "WriteSiteData"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.site.arn}/data/latest.json"] # the site bucket's ARN: exactly ONE object, nothing else
  }
}

resource "aws_iam_role_policy" "ingest" {
  name   = "ingest-least-privilege"
  role   = aws_iam_role.ingest.id
  policy = data.aws_iam_policy_document.ingest_permissions.json
}

# Zip the handler at plan time (archive provider). *.zip is gitignored.
data "archive_file" "ingest" {
  type        = "zip"
  source_file = "${path.module}/../lambda/ingest/handler.py" # path.module = the infra/ folder
  output_path = "${path.module}/build/ingest.zip"
}

resource "aws_lambda_function" "ingest" {
  function_name    = local.ingest_function_name # watt-next-dev-ingest
  description      = "Fetches the last 24h of RTE eCO2mix data into the data lake"
  role             = aws_iam_role.ingest.arn
  runtime          = "python3.13"      # verify the newest supported Python runtime in the AWS docs
  handler          = "handler.handler" # file handler.py, function handler()
  architectures    = ["arm64"]         # Graviton: cheaper per GB-second
  memory_size      = 128
  timeout          = 30
  filename         = data.archive_file.ingest.output_path
  source_code_hash = data.archive_file.ingest.output_base64sha256 # code change → redeploy

  environment {
    variables = {
      DATALAKE_BUCKET = aws_s3_bucket.datalake.bucket
      SITE_BUCKET     = aws_s3_bucket.site.bucket # the site bucket's full NAME # the site bucket's full NAME
    }
  }

  logging_config {
    log_format = "Text"
    log_group  = aws_cloudwatch_log_group.ingest.name # reference = implicit dependency: log group created first
  }

  # Hidden dependency: the function only references the role, not its policy.
  # Without this, the function could exist (and be invoked) before it has permissions.
  depends_on = [aws_iam_role_policy.ingest]
}

# ── Scheduler: the alarm clock ─────────────────────────────────────────
# Trust: only EventBridge Scheduler may wear this role, and only for schedules in THIS account
data "aws_iam_policy_document" "scheduler_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }
    condition { # confused-deputy protection: another account's schedule can't borrow this role
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id] # your data source, finally used!
    }
  }
}

resource "aws_iam_role" "scheduler" {
  name               = "${local.ingest_function_name}-scheduler-role"
  description        = "Lets EventBridge Scheduler invoke the ingestion Lambda"
  assume_role_policy = data.aws_iam_policy_document.scheduler_assume.json
}

# Permissions: one door — invoke this one function
data "aws_iam_policy_document" "scheduler_permissions" {
  statement {
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.ingest.arn]
  }

  statement {
    sid       = "SendUndeliveredToDlq"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.ingest_dlq.arn] # the queue's ARN
  }
}

resource "aws_iam_role_policy" "scheduler" {
  name   = "invoke-ingest-only"
  role   = aws_iam_role.scheduler.id
  policy = data.aws_iam_policy_document.scheduler_permissions.json
}

resource "aws_scheduler_schedule" "ingest" {
  name                = "${local.ingest_function_name}-schedule"
  description         = "Runs eCO2mix ingestion on a fixed rate"
  schedule_expression = var.ingest_schedule

  flexible_time_window {
    mode = "OFF" # run on time; "FLEXIBLE" lets AWS spread runs within a window
  }

  target {
    arn      = aws_lambda_function.ingest.arn
    role_arn = aws_iam_role.scheduler.arn

    retry_policy {
      maximum_retry_attempts = 2 # transient API hiccups; failed events go to a DLQ
    }
    dead_letter_config {
      arn = aws_sqs_queue.ingest_dlq.arn # the queue's ARN
    }
  }
}

# ── Failure parking lot ──────────────────────────────────────────
resource "aws_sqs_queue" "ingest_dlq" {
  name                      = "${local.name_prefix}-ingest-dlq"
  message_retention_seconds = 1209600 # 14 days (the max): time to investigate
  sqs_managed_sse_enabled   = true    # encrypted at rest, free
}

# Async failures: retry twice, then park the failed event in the DLQ
resource "aws_lambda_function_event_invoke_config" "ingest" {
  function_name                = aws_lambda_function.ingest.function_name # the function's NAME
  maximum_retry_attempts       = 2
  maximum_event_age_in_seconds = 3600

  destination_config {
    on_failure {
      destination = aws_sqs_queue.ingest_dlq.arn # the queue's ARN
    }
  }
}