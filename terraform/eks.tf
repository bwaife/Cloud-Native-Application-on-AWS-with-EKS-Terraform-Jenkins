
resource "aws_iam_role" "eks_cluster_role" {
    name = "eks-cluster-role"

  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume.json  
}

data "aws_iam_policy_document" "eks_cluster_assume" {
    statement {
      actions = [ "sts:AssumeRole" ]
      
      principals {
        type = "Service"
        identifiers = [ "eks.amazonaws.com" ]
      }
    }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSServicePolicy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

resource "aws_iam_role" "eks_node_role" {
    name = "eks-node-role"
    assume_role_policy = data.aws_iam_policy_document.eks_node_assume.json
}

data "aws_iam_policy_document" "eks_node_assume" {
    statement {
        actions = [ "sts:AssumeRole" ]

        principals {
            type = "Service"
            identifiers = [ "ec2.amazonaws.com" ]
        }
    }
  
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"

}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

#EKS Cluster (Control Plane)
resource "aws_eks_cluster" "eks" {
    name = "eks-cluster"
    role_arn = aws_iam_role.eks_cluster_role.arn
  
  vpc_config {
    subnet_ids = [aws_subnet.public_1.id,
                  aws_subnet.public_2.id,
                  aws_subnet.private_1.id,
                  aws_subnet.private_2.id]
                  endpoint_public_access = true
                  endpoint_private_access = false 
  }
    depends_on = [ aws_iam_role_policy_attachment.eks_cluster_AmazonEKSServicePolicy,
                   aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy 
                   ]
}

#EKS Node Group
resource "aws_eks_node_group" "eks_nodes" {
    cluster_name = aws_eks_cluster.eks.name
    node_group_name = "eks-node-group"
    node_role_arn = aws_iam_role.eks_node_role.arn
    subnet_ids = [ aws_subnet.private_1.id,
                  aws_subnet.private_2.id ]

    scaling_config {
        desired_size = 2
        max_size = 3
        min_size = 1
    }

    instance_types = [ "t3.medium" ]

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_node_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.eks_node_AmazonEKS_CNI_Policy
  ]  
}

#OID for the cluster

data "tls_certificate" "eks_cluster" {
  url = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list = [ "sts.amazonaws.com" ]
  thumbprint_list = [ data.tls_certificate.eks_cluster.certificates[0].sha1_fingerprint ]
  url = aws_eks_cluster.eks.identity[0].oidc[0].issuer
  
}

data "aws_iam_policy_document" "eks_assume_role_with_oidc" {
  statement {
    actions = [ "sts:AssumeRoleWithWebIdentity" ]
    effect = "Allow"
  

  principals {
    type = "Federated"
    identifiers = [aws_iam_openid_connect_provider.eks.arn]
}
  condition {
    test = "StringEquals"
    variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud"
    values = [ "sts.amazonaws.com" ]
  }
  }
}

resource "aws_iam_role" "eks_service_account_role" {
  name = "eks-service-account-role"
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role_with_oidc.json
  
}

data "aws_iam_policy_document" "service_account_policy" {
  statement {
    effect = "Allow"
    actions = [ "s3:GetObject", "s3:PutObject" ]
    resources = [ "*" ]
  }
}

resource "aws_iam_policy" "service_account_policy" {
  name = "eks-service-account-policy"
  policy = data.aws_iam_policy_document.service_account_policy.json
  
}

