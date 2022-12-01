# Set up the first resource for the IAM role. This ensures that the role has access to EKS.

# https://console.aws.amazon.com/eks/home
resource "aws_iam_role" "eks-iam-role" {
  name = var.cluster_name

  path = "/"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
  {
   "Effect": "Allow",
   "Principal": {
    "Service": "eks.amazonaws.com"
   },
   "Action": "sts:AssumeRole"
  }
 ]
}
EOF
}


# These two policies allow you to properly access EC2 instances (where the worker nodes run) and EKS.

# https://console.aws.amazon.com/iamv2/home#/roles/details/eks-cluster-rhombus?section=permissions
resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-iam-role.name
}
resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly-EKS" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks-iam-role.name
}

# Once the policies are attached, create the EKS cluster.

# https://console.aws.amazon.com/eks/home?#/clusters/eks-cluster-rhombus?selectedTab=cluster-networking-tab
resource "aws_eks_cluster" "rhombus-eks" {
  name    = var.cluster_name
  version = "1.24"

  role_arn = aws_iam_role.eks-iam-role.arn

  vpc_config {
    subnet_ids = aws_subnet.rhombus-subnet[*].id
  }

  depends_on = [
    aws_iam_role.eks-iam-role,
  ]
}

# Set up an IAM role for the worker nodes. 

# https://console.aws.amazon.com/iamv2/home#/roles/details/worker-rhombus?section=trust_relationships
resource "aws_iam_role" "workernodes" {
  name = var.worker_node

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

# https://console.aws.amazon.com/iamv2/home#/roles/details/worker-rhombus?section=permissions
resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.workernodes.name
}

# https://console.aws.amazon.com/iamv2/home#/roles/details/worker-rhombus?section=permissions
resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.workernodes.name
}

# https://console.aws.amazon.com/iamv2/home#/roles/details/worker-rhombus?section=permissions
resource "aws_iam_role_policy_attachment" "EC2InstanceProfileForImageBuilderECRContainerBuilds" {
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"
  role       = aws_iam_role.workernodes.name
}

# https://console.aws.amazon.com/iamv2/home#/roles/details/worker-rhombus?section=permissions
resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.workernodes.name
}

# The last bit of code is to create the worker nodes. In production, follow best practices and use at least three worker nodes.

# https://console.aws.amazon.com/eks/home?#/clusters/eks-cluster-rhombus/nodegroups/rhombus-workernodes
resource "aws_eks_node_group" "worker-node-group" {
  cluster_name    = aws_eks_cluster.rhombus-eks.name
  node_group_name = "rhombus-workernodes"
  node_role_arn   = aws_iam_role.workernodes.arn
  subnet_ids      = aws_subnet.rhombus-subnet[*].id
  instance_types  = ["t3.medium"]
  disk_size       = 5

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]
}

resource "null_resource" "kubeconfig" {
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --region ${var.region} --name ${var.cluster_name}"
  }
}