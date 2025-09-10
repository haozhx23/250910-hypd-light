#!/bin/bash

source init_envs
source stack_envs


echo "Using infrastructure from existing EKS stack:"
echo "EKS Cluster Name: $EKS_CLUSTER_NAME"
echo "VPC ID: $VPC_ID"
echo "Private Subnet ID: $PRIVATE_SUBNET_ID"
echo "Security Group ID: $SECURITY_GROUP_ID"
echo "S3 Bucket Name: $LIFECYCLE_S3_BUCKET_NAME"
echo "SageMaker Role ARN: $EXECUTION_ROLE"

# Extract SageMaker role name from ARN
SAGEMAKER_ROLE_NAME=$(echo $EXECUTION_ROLE | sed 's/.*role\///g')
echo "SageMaker Role Name: $SAGEMAKER_ROLE_NAME"

# Verify helm chart is installed
echo "Checking if HyperPod helm dependencies are installed..."
if ! helm list -n kube-system | grep -q "hyperpod-dependencies"; then
    echo "ERROR: HyperPod helm dependencies not found. Please run 2-cluster-configs.sh first."
    exit 1
fi

echo "HyperPod helm dependencies found. Proceeding with cluster creation..."

# Create HyperPod stack name
HP_STACK_NAME="hyperpod-$CLUSTER_TAG"

# Create parameters JSON for HyperPod stack
cat > /tmp/$HP_STACK_NAME-params.json << EOL 
[
  {"ParameterKey": "HyperPodClusterName", "ParameterValue": "$HP_CLUSTER_NAME"},
  {"ParameterKey": "EKSClusterName", "ParameterValue": "$EKS_CLUSTER_NAME"},
  {"ParameterKey": "SageMakerIAMRoleName", "ParameterValue": "$SAGEMAKER_ROLE_NAME"},
  {"ParameterKey": "PrivateSubnetId", "ParameterValue": "$PRIVATE_SUBNET_ID"},
  {"ParameterKey": "SecurityGroupId", "ParameterValue": "$SECURITY_GROUP_ID"},
  {"ParameterKey": "S3BucketName", "ParameterValue": "$LIFECYCLE_S3_BUCKET_NAME"},
  {"ParameterKey": "AcceleratedInstanceType", "ParameterValue": "$GPU_INSTANCE_TYPE"},
  {"ParameterKey": "AcceleratedInstanceCount", "ParameterValue": "$GPU_INSTANCE_COUNT"},
  {"ParameterKey": "AcceleratedEBSVolumeSize", "ParameterValue": "800"},
  {"ParameterKey": "AcceleratedThreadsPerCore", "ParameterValue": "2"},
  {"ParameterKey": "NodeRecovery", "ParameterValue": "None"},
  {"ParameterKey": "EnableInstanceStressCheck", "ParameterValue": "false"},
  {"ParameterKey": "EnableInstanceConnectivityCheck", "ParameterValue": "false"},
  {"ParameterKey": "UseContinuousNodeProvisioningMode", "ParameterValue": "false"}
]
EOL

TEMPLATE_FILE="3-hyperpod-cluster.yaml"

# Create HyperPod CloudFormation stack
echo "Creating HyperPod CloudFormation stack: $HP_STACK_NAME"
aws cloudformation create-stack \
--stack-name $HP_STACK_NAME \
--template-body file://$TEMPLATE_FILE \
--region $AWS_REGION \
--capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
--parameters file:///tmp/$HP_STACK_NAME-params.json

# Wait for stack creation to complete
echo "Waiting for HyperPod stack creation to complete..."
aws cloudformation wait stack-create-complete --stack-name $HP_STACK_NAME --region "$AWS_REGION"
