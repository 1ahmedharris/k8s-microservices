data "aws_iam_policy" "lambda_basic_execution_policy" {
  name = "AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role" "lambda_dynamodb_role" {
  name = "lamba-dynamodb-role"
  
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_counter_policy" {
  name = "visitor-counter-policy" 
  role = aws_iam_role.lambda_dynamodb_role.id 

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

resource "aws_iam_role_policy_attachment" "lambda_execution_role_policy_attachment" {
  role       = aws_iam_role.lambda_dynamodb_role.id 
  policy_arn = data.aws_iam_policy.lambda_basic_execution_policy.arn
}
