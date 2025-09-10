source init_envs

aws cloudformation describe-stacks --stack-name $CLOUD_FORMATION_FULL_STACK_NAME --region $AWS_REGION --query 'Stacks[0].Outputs' --output json | jq -r '
def map_output_to_env:
  if .OutputKey == "OutputEKSClusterName" then "export EKS_CLUSTER_NAME=" + .OutputValue
  elif .OutputKey == "OutputEKSClusterArn" then "export EKS_CLUSTER_ARN=" + .OutputValue
  elif .OutputKey == "OutputS3BucketName" then "export LIFECYCLE_S3_BUCKET_NAME=" + .OutputValue
  elif .OutputKey == "OutputSageMakerIAMRoleArn" then "export EXECUTION_ROLE=" + .OutputValue
  elif .OutputKey == "OutputVpcId" then "export VPC_ID=" + .OutputValue
  elif .OutputKey == "OutputPrivateSubnetIds" then "export PRIVATE_SUBNET_ID=" + .OutputValue
  elif .OutputKey == "OutputSecurityGroupId" then "export SECURITY_GROUP_ID=" + .OutputValue
  elif .OutputKey == "OutputHyperPodClusterName" then "export HP_CLUSTER_NAME=" + .OutputValue
  elif .OutputKey == "OutputHyperPodClusterArn" then "export HP_CLUSTER_ARN=" + .OutputValue
  else empty
  end;

(.[] | map_output_to_env)
' > stack_envs
