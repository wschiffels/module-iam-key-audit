variable "iam_key_audit_schedule" {
  description = "how often we run the lambda"
  default     = "cron(00 09 ? * MON-FRI *)"
}
