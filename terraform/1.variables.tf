#
# Variables Configuration
#

variable "app_environment" {
  default = "dev"
}

variable "vpc-subnets" {
  default = 2
}

variable "cluster_name" {
  default = "eks-cluster-rhombus"
  type    = string
}

variable "worker_node" {
  default = "worker-rhombus"
  type    = string
}

variable "region" {
  default = "us-west-2"
}

# Open the IAM console at https://console.aws.amazon.com/iam/
# 1.  Choose Access management -> Users
# 2.  Click the "Add users" button
# 3.  User name: rhombus-user
# 4.  Select AWS credential type: Access key - Programmatic access
# 5.  Click "Next Permissions"
# 6.  Pick the "Attach existing policies directly" option
# 7.  Select the checkbox "AdministratorAccess" name
# 8.  Click "Next Tags"
# 9.  Click "Next Review"
# 10. Click on the "Create user" button
# 11. Copy Access key and Secret access key
# 12. Click Close button

variable "access_key" {
  default = ""
}

variable "secret_key" {
  default = ""
}
