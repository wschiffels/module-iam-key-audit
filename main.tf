/* create IAM ROLE */
resource "aws_iam_role" "lambda_iam_key_audit" {
  name = "lambda_iam_key_audit"
  path = "/"

  assume_role_policy = <<POLICY
{
   "Version": "2012-10-17",
   "Statement": [
     {
       "Effect": "Allow",
       "Principal": {
         "Service": "lambda.amazonaws.com"
       },
       "Action": "sts:AssumeRole"
     }
   ]
}
POLICY
}

/* Policy attachements */
resource "aws_iam_role_policy_attachment" "CloudWatchLogs-policy-attachment" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  role       = "${aws_iam_role.lambda_iam_key_audit.name}"
}

resource "aws_iam_role_policy" "lambda_iam_key_audit_policy" {
  name = "lambda_iam_key_audit_policy"
  role = "${aws_iam_role.lambda_iam_key_audit.name}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Effect": "Allow",
          "Action": [
              "iam:UpdateAccessKey",
              "iam:ListAccessKeys",
              "iam:GetAccessKeyLastUsed"
          ],
          "Resource": "arn:aws:iam::*:user/*"
      },
      {
          "Effect": "Allow",
          "Action": [
              "iam:ListUsers"
          ],
          "Resource": "*"
      }
  ]
}
  POLICY
}

/* Lambda function */
data "archive_file" "source" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "lambda-iam_key_audit" {
  description      = "Lambda function to audit IAM keys."
  filename         = "${path.module}/lambda_function.zip"
  function_name    = "IAMAccessKeyAudit"
  handler          = "lambda_function.handler"
  role             = "${aws_iam_role.lambda_iam_key_audit.arn}"
  runtime          = "python3.7"
  source_code_hash = "${data.archive_file.source.output_base64sha256}"
  timeout          = "900"
}

/* CloudWatch */
resource "aws_cloudwatch_event_rule" "event_rule-timer" {
  description         = "trigger Lambda IAMAccessKeyAudit"
  name                = "IAMAccessKeyAudit-Trigger"
  schedule_expression = "${var.iam_key_audit_schedule}"
}

resource "aws_cloudwatch_event_target" "event_target" {
  arn       = "${aws_lambda_function.lambda-iam_key_audit.arn}"
  rule      = "${aws_cloudwatch_event_rule.event_rule-timer.name}"
  target_id = "lambda-iam_key_audit-target"
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda" {
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda-iam_key_audit.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.event_rule-timer.arn}"
  statement_id  = "AllowIAMKeyAuditFromCloudWatch"

  depends_on = [
    "aws_lambda_function.lambda-iam_key_audit",
  ]
}
