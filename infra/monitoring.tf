# ── Alerting: where notifications go ─────────────────────────────
# Encryption decision: Unencrypted since the topic only covers non-confidential Cloudwatch alerts, not worth the extra KMS key and cost
# To revisit if messages ever include data.
resource "aws_sns_topic" "alerts" {
  name = "${local.name_prefix}-alerts"
}

resource "aws_sns_topic_subscription" "alert_email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email # the email address: which variable?
}

# ── Alarms on the ingestion Lambda ─────────────────────────────────
locals {
  ingest_alarms = {
    errors = {
      description        = "Ingestion Lambda failed at least once in 15 minutes"
      metric_name        = "Errors"
      comparison         = "GreaterThanOrEqualToThreshold"
      period             = 900
      treat_missing_data = "notBreaching" # no data = no errors = fine
    }
    no_invocations = {
      description        = "Scheduler has not invoked the Ingest Lambda function" # what does this alarm mean, in plain words?
      metric_name        = "Invocations"
      comparison         = "LessThanThreshold"
      period             = 1800
      treat_missing_data = "breaching"
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "ingest" {
  for_each = local.ingest_alarms # which local map?

  alarm_name          = "${local.name_prefix}-ingest-${each.key}" # the map KEY (errors / no_invocations)
  alarm_description   = each.value.description
  namespace           = "AWS/Lambda"
  metric_name         = each.value.metric_name
  statistic           = "Sum"
  period              = each.value.period
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = each.value.comparison
  treat_missing_data  = each.value.treat_missing_data

  dimensions = {
    FunctionName = aws_lambda_function.ingest.function_name
  }

  alarm_actions = [aws_sns_topic.alerts.arn] # the topic's ARN, inside a list
  ok_actions    = [aws_sns_topic.alerts.arn]
}