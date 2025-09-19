#!/bin/bash

aws configure set region ap-southeast-1
aws eks update-kubeconfig --name wsc2025-cluster

echo --------------------
echo "       1-1        "
echo --------------------
aws ecr describe-repositories --repository-names app-repo --query 'repositories[0].repositoryName' --output text

echo --------------------
echo "       1-2        "
echo --------------------
aws ecr list-images --repository-name app-repo --query 'imageIds[?imageTag!=`null`].imageTag' --output text

echo --------------------
echo "       1-3        "
echo --------------------
aws eks describe-cluster --name wsc2025-cluster --query 'cluster.[name, version]' --output text

echo --------------------
echo "       1-4        "
echo --------------------
aws eks describe-nodegroup --cluster-name wsc2025-cluster --nodegroup-name wsc2025-app-ng \
  --query 'nodegroup.[nodegroupName, instanceTypes]' --output text

echo --------------------
echo "       1-5        "
echo --------------------
kubectl get deploy -n wsc2025

echo --------------------
echo "       1-6        "
echo --------------------
aws elbv2 describe-load-balancers \
  --query "LoadBalancers[?LoadBalancerName=='wsc2025-cicd-alb'].LoadBalancerName" \
  --output text

echo --------------------
echo "       1-7        "
echo --------------------  
ENDPOINT=$(aws elbv2 describe-load-balancers \
  --query "LoadBalancers[?LoadBalancerName=='wsc2025-cicd-alb'].DNSName" \
  --output text)
curl http://$ENDPOINT/

echo --------------------
echo "       1-8        "
echo --------------------
echo Manual

echo --------------------
echo "       1-9        "
echo --------------------
echo Manual

echo --------------------
echo "       1-10       "
echo --------------------
echo Manual

echo --------------------
echo "       1-11       "
echo --------------------
echo Manual