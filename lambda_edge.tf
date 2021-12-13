data "archive_file" "lambda_rewrite_uri_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda_rewrite_uri.js.zip"
  source_file = "${path.module}/lambda_rewrite_uri.js"
}

resource "aws_iam_role" "lambda_execution" {
  name_prefix        = "lambda-execution-role-"
  description        = "aws lambda basic execution role"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "edgelambda.amazonaws.com",
          "lambda.amazonaws.com"
        ]
      },
      "Effect": "Allow"
    }
  ]
})
  managed_policy_arns  = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
  tags = var.tags
}

resource "aws_lambda_function" "lambda_rewrite_uri" {
  description      = "lambda function for request URI rewrite"
  filename         = "${path.module}/lambda_rewrite_uri.js.zip"
  function_name    = "uri_rewrite"
  handler          = "lambda_rewrite_uri.handler"
  source_code_hash = data.archive_file.lambda_rewrite_uri_zip.output_base64sha256
  provider         = aws #.aws_cloudfront
  publish          = true
  role             = aws_iam_role.lambda_execution.arn
  runtime          = "nodejs14.x"

  tags = var.tags
}