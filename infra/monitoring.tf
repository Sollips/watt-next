# ── Alerting: where notifications go ─────────────────────────────
# Encryption decision: Unencrypted since the topic only covers non-confidential Cloudwatch alerts, not worth the extra KMS key and cost
# To revisit if messages ever include data.
resource "aws_sns_topic" "alerts" {
  name = "${local.name_prefix}-alerts"
}

resource "aws_sns_topic_subscription" "alert_email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ── Alarms on the ingestion Lambda ─────────────────────────────────
locals {
  ingest_alarms = {
    errors = {
      description        = "Ingestion Lambda failed at least once in 15 minutes"
      namespace          = "AWS/Lambda"
      metric_name        = "Errors"
      statistic          = "Sum"
      comparison         = "GreaterThanOrEqualToThreshold"
      period             = 900
      treat_missing_data = "notBreaching"
      dimensions         = { FunctionName = aws_lambda_function.ingest.function_name }
    }
    no_invocations = {
      description        = "Scheduler has not invoked the ingestion Lambda in 30 minutes"
      namespace          = "AWS/Lambda"
      metric_name        = "Invocations"
      statistic          = "Sum"
      comparison         = "LessThanThreshold"
      period             = 1800
      treat_missing_data = "breaching"
      dimensions         = { FunctionName = aws_lambda_function.ingest.function_name }
    }
    dlq_messages = {
      description        = "At least one failed ingestion event is waiting in the DLQ"
      namespace          = "AWS/SQS"
      metric_name        = "ApproximateNumberOfMessagesVisible"
      statistic          = "Maximum" # the highest count seen in the period
      comparison         = "GreaterThanOrEqualToThreshold"
      period             = 300
      treat_missing_data = "notBreaching"
      dimensions         = { QueueName = aws_sqs_queue.ingest_dlq.name } # the queue's NAME, by reference
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "ingest" {
  for_each = local.ingest_alarms

  alarm_name          = "${local.name_prefix}-ingest-${each.key}"
  alarm_description   = each.value.description
  namespace           = each.value.namespace # ← from the map
  metric_name         = each.value.metric_name
  statistic           = each.value.statistic # ← from the map
  period              = each.value.period
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = each.value.comparison
  treat_missing_data  = each.value.treat_missing_data
  dimensions          = each.value.dimensions # ← from the map (the whole map at once)

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}