
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