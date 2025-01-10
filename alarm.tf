# SNS Topic
resource "aws_sns_topic" "chichao_alarm_topic" {
  name = "chichao-assignment216-alarm-topic"
}

# SNS Topic Policy
resource "aws_sns_topic_policy" "sns_topic_policy" {
  arn = aws_sns_topic.chichao_alarm_topic.arn

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action    = "sns:Publish"
        Resource  = aws_sns_topic.chichao_alarm_topic.arn
      }
    ]
  })
}

# CloudWatch Metric Alarm
resource "aws_cloudwatch_metric_alarm" "terraform_alarm_service" {
  alarm_name          = "cc-info-count-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "info-count"
  namespace           = "/moviedb-api/chichao2"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Alarm when info-count metric exceeds 10 in a 1-minute interval"
  actions_enabled     = true

  alarm_actions = [aws_sns_topic.chichao_alarm_topic.arn]
}
