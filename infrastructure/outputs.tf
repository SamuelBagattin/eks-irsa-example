output "pod_role_arn" {
  value       = aws_iam_role.my_pod_role.arn
  description = "ARN of the IAM role assumed by the app"
}