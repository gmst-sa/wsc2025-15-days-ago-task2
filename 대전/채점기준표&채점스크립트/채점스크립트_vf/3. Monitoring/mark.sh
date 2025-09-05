#!/bin/bash

# Export
aws configure set default.region ap-southeast-1
aws configure set default.output json

echo =====3-1-A=====
aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=wsi-vpc" \
  --query "Vpcs[*].{Name:Tags[?Key=='Name']|[0].Value}" \
  --output table
echo


echo =====3-2-A=====
filters=()
for name in "${SUBNET_NAMES[@]}"; do
  filters+=("Name=tag:Name,Values=$name")
done
aws ec2 describe-subnets \
  --filters "${filters[@]}" \
  --query "Subnets[].{Name:Tags[?Key=='Name']|[0].Value}" \
  --output table
echo

echo =====3-3-A=====
aws ecs list-clusters \
  --query "clusterArns[?contains(@, '${wsi-app-cluster}')]" \
  --output text | \
  xargs -n1 basename | \
  jq -R -s 'split("\n")[:-1] | map({Name: .})'
echo

echo =====3-4-A=====
aws cloudwatch list-dashboards \
  --region "ap-northeast-1" \
  --query "DashboardEntries[?DashboardName=='wsi-dashboard'].[DashboardName]" \
  --output table
echo

echo =====3-5-A=====
echo "for i in {1..50}
do
  curl -X GET http://<접근가능한 엔드포인트>/healthcheck
done"
echo
echo "manual"
echo

echo =====3-6-A=====
echo "for i in {1..50}
do
  curl -X GET http://<접근가능한 엔드포인트>/healthcheck
done"
echo
echo "manual"
echo

echo =====3-7-A=====
echo "manual"
echo

echo =====3-8-A=====
echo "manual"