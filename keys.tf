# resource "aws_kms_key" "eks_secrets" {
#   description             = "Amazon EKS cluster secrets encryption key"
#   enable_key_rotation     = true
#   deletion_window_in_days = 7
# }

# resource "aws_kms_key" "eks_volumes" {
#   description             = "Amazon EBS volumes encryption key"
#   enable_key_rotation     = true
#   deletion_window_in_days = 7
# }
