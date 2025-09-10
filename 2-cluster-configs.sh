#!/bin/bash

source init_envs

./fetch-creation-cf-info.sh

source stack_envs

aws eks update-kubeconfig --name $EKS_CLUSTER_NAME --region $AWS_REGION

eksctl utils associate-iam-oidc-provider \
    --region ${AWS_REGION} \
    --cluster ${EKS_CLUSTER_NAME} \
    --approve

## Add eks helm charts
helm repo add eks https://aws.github.io/eks-charts
## Make sure you update to the latest version
helm repo update eks

# helm repo add kuberay https://ray-project.github.io/kuberay-helm/
# helm repo update

# helm install kuberay-operator kuberay/kuberay-operator --version 1.2.0 --namespace kube-system

# helm ls -n kube-system

# 检查并下载 SageMaker HyperPod CLI 仓库
if [ ! -d "./sagemaker-hyperpod-cli" ]; then
    echo "Cloning SageMaker HyperPod CLI repository..."
    git clone https://github.com/aws/sagemaker-hyperpod-cli.git
else
    echo "SageMaker HyperPod CLI repository already exists, skipping clone..."
fi

# cd /home/ubuntu/workspace/HyperPod-InstantStart-BASE/cli-min/sagemaker-hyperpod-cli/helm_chart/HyperPodHelmChart && helm dependency build

kubectl create namespace aws-hyperpod

helm dependency build sagemaker-hyperpod-cli/helm_chart/HyperPodHelmChart

# 安装 Helm Chart
helm install hyperpod-dependencies ./sagemaker-hyperpod-cli/helm_chart/HyperPodHelmChart \
  --namespace kube-system \
  --create-namespace \
  --set trainingOperators.enabled=false \
  --set nvidia-device-plugin.devicePlugin.enabled=true \
  --set neuron-device-plugin.devicePlugin.enabled=false \
  --set aws-efa-k8s-device-plugin.devicePlugin.enabled=true \
  --set mpi-operator.enabled=false \
  --set health-monitoring-agent.enabled=true \
  --set deep-health-check.enabled=false \
  --set job-auto-restart.enabled=false \
  --set hyperpod-patching.enabled=true


# helm uninstall hyperpod-dependencies -n kube-system