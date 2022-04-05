terraform {
  required_providers {
    aws = {
      version = "~> 4.0"
      source  = "hashicorp/aws"
    }
    tls = {
      version = "~> 3.0"
      source  = "hashicorp/tls"
    }
  }
}

provider "aws" {
  profile = var.aws_profile
  region  = "eu-west-1"
}

resource "aws_eks_cluster" "main" {
  name     = "main"
  role_arn = aws_iam_role.eks_cluster.arn

  enabled_cluster_log_types = ["api", "audit"]

  vpc_config {
    endpoint_public_access  = false
    endpoint_private_access = true
    subnet_ids              = var.subnet_ids
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
  ]
}

resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/main/cluster"
  retention_in_days = 7
}

resource "aws_security_group_rule" "eks_cluster_from_internal" {
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  to_port           = 443
  type              = "ingress"
  cidr_blocks       = ["10.0.0.0/8"]
}


resource "aws_iam_role" "eks_cluster" {
  name               = "eks-cluster"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster.json
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

data "aws_iam_policy_document" "eks_cluster" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["eks.amazonaws.com"]
      type        = "Service"
    }
    actions = ["sts:AssumeRole"]
  }
}

