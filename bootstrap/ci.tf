# ── CI access: GitHub Actions → AWS via OIDC (no stored keys) ──────────────
locals {
  github_repo = "Sollips/watt-next"
  oidc_host   = "token.actions.githubusercontent.com"
}

# AWS trusts tokens signed by GitHub Actions
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://${local.oidc_host}"
  client_id_list = ["sts.amazonaws.com"] # the audience GitHub's AWS login action requests
  # thumbprint_list omitted: optional in recent provider versions (verify in the registry docs)
}

# ── Plan role: PR runs only; read + state lock ──
data "aws_iam_policy_document" "ci_plan_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn] # the OIDC provider's ARN
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition { # THE important line: only pull-request runs of THIS repo
      test     = "StringEquals"
      variable = "${local.oidc_host}:sub"
      values   = ["repo:${local.github_repo}:pull_request"]
    }
  }
}

resource "aws_iam_role" "ci_plan" {
  name                 = "watt-next-ci-plan"
  description          = "GitHub Actions: terraform plan on pull requests (read-only)"
  assume_role_policy   = data.aws_iam_policy_document.ci_plan_trust.json
  max_session_duration = 3600 # credentials expire after 1 hour at most
}

resource "aws_iam_role_policy_attachment" "ci_plan_readonly" {
  role       = aws_iam_role.ci_plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# plan takes the state lock, so it must create/delete the .tflock object (and nothing else)
data "aws_iam_policy_document" "ci_plan_lock" {
  statement {
    sid       = "StateLockOnly"
    actions   = ["s3:PutObject", "s3:DeleteObject"]
    resources = ["${module.tfstate.arn}/watt-next/dev/infra.tfstate.tflock"]
  }
}

resource "aws_iam_role_policy" "ci_plan_lock" {
  name   = "state-lock"
  role   = aws_iam_role.ci_plan.id
  policy = data.aws_iam_policy_document.ci_plan_lock.json
}

# ── Apply role: Runs in the production environnment; Changes infrastructure ──

data "aws_iam_policy_document" "ci_apply_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn] # the OIDC provider's ARN
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition { # THE important line: only runs in THIS repo's "production" environment
      test     = "StringEquals"
      variable = "${local.oidc_host}:sub"
      values   = ["repo:${local.github_repo}:environment:production"]
    }
  }
}

resource "aws_iam_role" "ci_apply" {
  name                 = "watt-next-ci-apply"
  description          = "GitHub Actions: terraform apply in production"
  assume_role_policy   = data.aws_iam_policy_document.ci_apply_trust.json
  max_session_duration = 3600 # credentials expire after 1 hour at most
}

resource "aws_iam_role_policy_attachment" "ci_apply" {
  role       = aws_iam_role.ci_apply.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}