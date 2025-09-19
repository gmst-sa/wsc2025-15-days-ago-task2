#!/bin/bash

aws configure set region us-east-1

echo --------------------
echo "       3-1        "
echo --------------------
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=wsc2025-app-server" \
  --query "Reservations[*].Instances[*].Tags[?Key=='Name'].Value[]" \
  --output text
IP=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=wsc2025-app-server" \
  --query "Reservations[*].Instances[*].PublicIpAddress" \
  --output text)
curl "http://$IP:5000"
curl "http://$IP:5000/login?name=admin'--&secret=anything"
curl "http://$IP:5000/lookup?id=id%3D1+OR+1%3D1"

echo --------------------
echo "       3-2        "
echo --------------------
aws elbv2 describe-load-balancers \
  --names wsc2025-waf-alb \
  --query "LoadBalancers[*].[LoadBalancerName, Type, Scheme]" \
  --output text

echo --------------------
echo "       3-3        "
echo --------------------
aws wafv2 list-web-acls \
  --scope REGIONAL \
  --query "WebACLs[?Name=='wsc2025-waf'].Name" \
  --output text

echo --------------------
echo "       3-4        "
echo --------------------  
export ALB_ENDPOINT=$(aws elbv2 describe-load-balancers \
  --names wsc2025-waf-alb \
  --query "LoadBalancers[*].DNSName" \
  --output text)
curl "http://$ALB_ENDPOINT/login?name=admin'--&secret=anything"

echo --------------------
echo "       3-5        "
echo --------------------  
export ALB_ENDPOINT=$(aws elbv2 describe-load-balancers \
  --names wsc2025-waf-alb \
  --query "LoadBalancers[*].DNSName" \
  --output text)
curl "http://$ALB_ENDPOINT/lookup?id=id%3D1+OR+1%3D1"