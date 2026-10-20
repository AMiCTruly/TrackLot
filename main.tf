terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# 1. DynamoDB Table for Idempotent State & Deduplication
resource "aws_dynamodb_table" "auction_alerts" {
  name         = "AuctionAlerts"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "lot_id"

  attribute {
    name = "lot_id"
    type = "S"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }
}

# 2. IAM Role & Least-Privilege Policies for Lambda
resource "aws_iam_role" "lambda_exec_role" {
  name = "auction_monitor_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name = "auction_monitor_permissions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem"
        ]
        Resource = aws_dynamodb_table.auction_alerts.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# 3. AWS Lambda Function
resource "aws_lambda_function" "auction_bot" {
  filename         = "lambda_function.zip"
  function_name    = "auction-monitor-service"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "main.lambda_handler"
  runtime          = "python3.11"
  timeout          = 30
  memory_size      = 256
  source_code_hash = filebase64sha256("lambda_function.zip")

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.auction_alerts.name
      DISCORD_WEBHOOK_URL = var.discord_webhook_url
    }
  }
}

variable "discord_webhook_url" {
  type        = string
  description = "Discord Webhook URL for alerting"
  sensitive   = true
}

# 4. Amazon EventBridge Trigger (Runs every 15 minutes)
resource "aws_cloudwatch_event_rule" "schedule" {
  name                = "auction-monitor-cron"
  description         = "Trigger auction scraper Lambda every 15 minutes"
  schedule_expression = "rate(15 minutes)"
}

resource "aws_cloudwatch_event_target" "target" {
  rule      = aws_cloudwatch_event_rule.schedule.name
  target_id = "AuctionBotTarget"
  arn       = aws_lambda_function.auction_bot.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auction_bot.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule.arn
}