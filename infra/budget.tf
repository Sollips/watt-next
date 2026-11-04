# Budget created by hand on day 1, imported (no recreation)
resource "aws_budgets_budget" "monthly" {
  account_id   = data.aws_caller_identity.current.account_id # never hard-code account IDs
  name         = "monthly-cost-guardrail"
  budget_type  = "COST"
  limit_amount = "5.0"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  # Period recorded by AWS (end = AWS's "no end date" default); kept to avoid churn
  time_period_start = "2026-10-01_00:00"
  time_period_end   = "2087-06-15_00:00"

  notification {
    comparison_operator        = "GREATER_THAN"
    notification_type          = "ACTUAL"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    subscriber_email_addresses = [var.alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    notification_type          = "FORECASTED"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    subscriber_email_addresses = [var.alert_email]
  }
}