data "aws_iam_policy" "lambda_basic_execution_policy" {
  name = "AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy" "lambda_vpc_access_policy" {
  name = "AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_counter_policy" {
  name = "visitor-counter-policy" 
  role = aws_iam_role.lambda_role.id 

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "dynamodb:GetItem",
          "dynamodb:UpdateItem"
        ],
        Resource = [aws_dynamodb_table.visitor_count_table.arn]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.id 
  policy_arn = data.aws_iam_policy.lambda_basic_execution_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = data.aws_iam_policy.lambda_vpc_access_policy.arn
}

resource "aws_cloudwatch_log_group" "lambda_counter_api_log_group" {
  name              = "/aws/lambda/aitc-lamba-function" 
  retention_in_days = 30                             
}

resource "aws_lambda_function" "lambda_counter_api" {
  function_name    = var.lambda_function
  filename         = var.lambda_counter_zip
  source_code_hash = filebase64sha256(var.lambda_counter_zip)
  handler          = "lambda_function.lambda_handler"
  role             = aws_iam_role.lambda_role.arn
  runtime          = "python3.13"
  timeout          = 5 
  memory_size      = 128 

  vpc_config {
  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [aws_security_group.lambda_sg.id]
  }
  
  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.visitor_count_table.name 
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda_counter_api_log_group,
    aws_iam_role.lambda_dynamodb_role,
    aws_iam_role_policy.lambda_counter_policy,
    aws_iam_role_policy_attachment.lambda_execution_role_policy_attachment,
  ]
}

resource "aws_lambda_permission" "distribution_lambda" {
  action                 = "lambda:invokeFunctionUrl"
  function_name          = aws_lambda_function.lambda_counter_api.function_name
  function_url_auth_type = "NONE"
  principal              = "*"

  lifecycle {
    replace_triggered_by = [
      aws_lambda_function.lambda_counter_api
    ]
  }
}

resource "aws_lambda_function_url" "lambda_counter_url" {
  function_name      = aws_lambda_function.lambda_counter_api.function_name
  authorization_type = "NONE" 
  invoke_mode        = "BUFFERED"

  cors {
    allow_credentials = false
    allow_origins     = ["*"] 
    allow_methods     = ["GET", "POST"]
    allow_headers     = ["content-type"]
    expose_headers    = []
    max_age           = 86400
  }
}

output "lambda_counter_url_output" {
  value       = aws_lambda_function_url.lambda_counter_url.function_url
  description = "URL endpoint for Lambda visitor counter function."
}



