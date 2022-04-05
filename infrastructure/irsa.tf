# Get EKS cluster certificate thumbprint
data "tls_certificate" "eks_cluster" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# Create the OIDC provider
resource "aws_iam_openid_connect_provider" "eks_cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_cluster.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
}



# Create the trust policy for the role associated to the app
data "aws_iam_policy_document" "my_pod_role_trusted_identities" {
  statement {
    # Allow through AssumeRoleWithWebIdentity
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    # Only if the requester is authenticated with the service-account "my-serviceaccount" in the namespace "default"
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks_cluster.url, "https:#", "")}:sub"
      values   = ["system:serviceaccount:default:my-serviceaccount"]
    }

    # Allow assuming the role through the previously created OIDC provider
    principals {
      identifiers = [aws_iam_openid_connect_provider.eks_cluster.arn]
      type        = "Federated"
    }
  }
}

# Create the IAM role and grant it permissions
resource "aws_iam_role" "my_pod_role" {
  assume_role_policy = data.aws_iam_policy_document.my_pod_role_trusted_identities.json
  name               = "my-pod-role"
  inline_policy {
    name   = "s3ListAllMyBuckets"
    policy = data.aws_iam_policy_document.my_pod_role_policy.json
  }
}

data "aws_iam_policy_document" "my_pod_role_policy" {
  statement {
    # S3 list all my buckets
    actions   = ["s3:ListAllMyBuckets"]
    effect    = "Allow"
    resources = ["*"]
  }
}