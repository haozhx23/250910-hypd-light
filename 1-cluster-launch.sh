#!/bin/bash

source init_envs
printenv | grep -E "(CLOUD_FORMATION|AWS_|EKS_|HP_|GPU_|DEPLOY_|ACCOUNT_|STACK_)"


# aws s3 mb s3://$DEPLOY_MODEL_S3_BUCKET --region ${AWS_REGION}
# sleep 10

# Create parameters JSON with FTP-specific configuration
cat > /tmp/$CLOUD_FORMATION_FULL_STACK_NAME-params.json << EOL 
[
  {"ParameterKey": "EKSClusterName", "ParameterValue": "$EKS_CLUSTER_NAME"},
  {"ParameterKey": "HyperPodClusterName", "ParameterValue": "$HP_CLUSTER_NAME"},
  {"ParameterKey": "ResourceNamePrefix", "ParameterValue": "$EKS_CLUSTER_NAME"},
  {"ParameterKey": "AvailabilityZoneId", "ParameterValue": "$AWS_AZ"},
  {"ParameterKey": "AcceleratedInstanceType", "ParameterValue": "$GPU_INSTANCE_TYPE"},
  {"ParameterKey": "AcceleratedInstanceCount", "ParameterValue": "$GPU_INSTANCE_COUNT"},
  {"ParameterKey": "AcceleratedTrainingPlanArn", "ParameterValue": "arn:aws:sagemaker:$AWS_REGION:$ACCOUNT_ID:training-plan/$FTP_NAME"},
  {"ParameterKey": "AcceleratedEBSVolumeSize", "ParameterValue": "800"},
  {"ParameterKey": "AcceleratedThreadsPerCore", "ParameterValue": "2"},
  {"ParameterKey": "NodeRecovery", "ParameterValue": "None"},
  {"ParameterKey": "EnableInstanceStressCheck", "ParameterValue": "false"},
  {"ParameterKey": "EnableInstanceConnectivityCheck", "ParameterValue": "false"},
  {"ParameterKey": "UseContinuousNodeProvisioningMode", "ParameterValue": "false"},
  {"ParameterKey": "CreateHelmChartStack", "ParameterValue": "false"}
]
EOL

# {"ParameterKey": "ParticipantRoleArn", "ParameterValue": "$DEV_IAM_ROLE_ARN"}

# curl -o main-stack.yaml https://raw.githubusercontent.com/aws-samples/awsome-distributed-training/refs/heads/main/1.architectures/7.sagemaker-hyperpod-eks/cfn-templates/nested-stacks/main-stack.yaml 
TEMPLATE_FILE="1-main-stack-eks-control.yaml"

# Create CloudFormation stack
echo "Creating CloudFormation stack: $CLOUD_FORMATION_FULL_STACK_NAME"
aws cloudformation create-stack \
--stack-name $CLOUD_FORMATION_FULL_STACK_NAME \
--template-body file://$TEMPLATE_FILE \
--region $AWS_REGION \
--capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
--parameters file:///tmp/$CLOUD_FORMATION_FULL_STACK_NAME-params.json

# Wait for stack creation to complete
echo "Waiting for stack creation to complete..."
aws cloudformation wait stack-create-complete --stack-name $CLOUD_FORMATION_FULL_STACK_NAME --region "$AWS_REGION"

echo "Stack creation completed successfully!"
