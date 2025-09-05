#!/bin/bash

aws configure set default.region ap-southeast-1

echo =====1-1=====
aws ec2 describe-vpcs --filter Name=tag:Name,Values=skills-consumer-vpc --query "Vpcs[].CidrBlock" \
; aws ec2 describe-vpcs --filter Name=tag:Name,Values=skills-service-vpc --query "Vpcs[].CidrBlock"
echo

echo =====1-2=====
aws ec2 describe-subnets --filter Name=tag:Name,Values=skills-consumer-public-subnet-a --query "Subnets[0].CidrBlock" \
; aws ec2 describe-subnets --filter Name=tag:Name,Values=skills-consumer-public-subnet-c --query "Subnets[0].CidrBlock" \
; aws ec2 describe-subnets --filter Name=tag:Name,Values=skills-consumer-workload-subnet-a --query "Subnets[0].CidrBlock" \
; aws ec2 describe-subnets --filter Name=tag:Name,Values=skills-consumer-workload-subnet-c --query "Subnets[0].CidrBlock" \
; aws ec2 describe-subnets --filter Name=tag:Name,Values=skills-service-public-subnet-a --query "Subnets[0].CidrBlock" \
; aws ec2 describe-subnets --filter Name=tag:Name,Values=skills-service-public-subnet-c --query "Subnets[0].CidrBlock" \
; aws ec2 describe-subnets --filter Name=tag:Name,Values=skills-service-workload-subnet-a --query "Subnets[0].CidrBlock" \
; aws ec2 describe-subnets --filter Name=tag:Name,Values=skills-service-workload-subnet-c --query "Subnets[0].CidrBlock"
echo

echo =====1-3=====
aws ec2 describe-route-tables --filter Name=tag:Name,Values=skills-consumer-public-rt --query "RouteTables[].Routes[].GatewayId" \
; aws ec2 describe-route-tables --filter Name=tag:Name,Values=skills-service-public-rt --query "RouteTables[].Routes[].GatewayId" \
; aws ec2 describe-route-tables --filter Name=tag:Name,Values=skills-consumer-workload-rt-a --query "RouteTables[].Routes[].NatGatewayId" \
; aws ec2 describe-route-tables --filter Name=tag:Name,Values=skills-consumer-workload-rt-c --query "RouteTables[].Routes[].NatGatewayId" \
; aws ec2 describe-route-tables --filter Name=tag:Name,Values=skills-service-workload-rt-a --query "RouteTables[].Routes[].NatGatewayId" \
; aws ec2 describe-route-tables --filter Name=tag:Name,Values=skills-service-workload-rt-c --query "RouteTables[].Routes[].NatGatewayId"
echo

echo =====2-1=====
aws vpc-lattice list-service-networks --query "items[?contains(name, 'skills-app-service-network')].name" --output text
echo

echo =====2-2=====
aws vpc-lattice list-services --query "items[?contains(name, 'skills-app-service')].name" --output text
echo

echo =====2-3=====
aws vpc-lattice list-target-groups --query "items[?contains(name, 'skills-alb-tg')].name" --output text
echo

echo =====3-1=====
aws ec2 describe-instances --filter Name=tag:Name,Values=skills-bastion --query "Reservations[].Instances[].InstanceType"
echo

echo =====3-2=====
aws ec2 describe-instances --filter Name=tag:Name,Values=skills-bastion --query "Reservations[].Instances[].PublicIpAddress"
aws ec2 describe-addresses --query "Addresses[].PublicIp"
echo

echo =====3-3=====
INSTANCE_NAME_TAG="skills-bastion"
INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$INSTANCE_NAME_TAG" "Name=instance-state-name,Values=running,pending,stopping,stopped" --query "Reservations[0].Instances[0].InstanceId" --output text)
AMI_ID=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query "Reservations[0].Instances[0].ImageId" --output text)
AMI_DESCRIPTION=$(aws ec2 describe-images --image-ids "$AMI_ID" --query "Images[0].Description" --output text)
INSTANCE_SG_NAME=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query "Reservations[0].Instances[0].SecurityGroups[0].GroupName" --output text)

echo "$AMI_DESCRIPTION"
echo "$INSTANCE_SG_NAME"

echo =====3-4=====
POLICY_ARNS=$(aws iam list-attached-role-policies --role-name skills-bastion-role --query "AttachedPolicies[].PolicyArn" --output text)
for POLICY_ARN in $POLICY_ARNS; do
POLICY_VERSION=$(aws iam get-policy --policy-arn $POLICY_ARN --query "Policy.DefaultVersionId" --output text)
POLICY_DOCUMENT=$(aws iam get-policy-version --policy-arn $POLICY_ARN --version-id $POLICY_VERSION --query "PolicyVersion.Document" --output json)
echo "$POLICY_DOCUMENT"
done
echo

echo =====4-1=====
aws elbv2 describe-load-balancers --query "LoadBalancers[].{Name:LoadBalancerName,Type:Scheme,Zones:AvailabilityZones[].ZoneName}" --output json
echo

echo =====5-1=====
EXTERNAL_ALB_DNS=$(aws elbv2 describe-load-balancers --names skills-consumer-alb --query "LoadBalancers[].DNSName" --output text)
curl -s http://$EXTERNAL_ALB_DNS/health
echo

echo =====5-2=====
EXTERNAL_ALB_DNS=$(aws elbv2 describe-load-balancers --names skills-consumer-alb --query "LoadBalancers[].DNSName" --output text)
curl http://$EXTERNAL_ALB_DNS/users -X POST -H "Content-Type: application/json" -d '{"UserId": "user123", "Name": "John Doe", "SkillLevel": "Intermediate"}'
echo

echo =====5-3=====
EXTERNAL_ALB_DNS=$(aws elbv2 describe-load-balancers --names skills-consumer-alb --query "LoadBalancers[].DNSName" --output text)
curl -s http://$EXTERNAL_ALB_DNS/users/user123
echo

echo =====5-4=====
EXTERNAL_ALB_DNS=$(aws elbv2 describe-load-balancers --names skills-consumer-alb --query "LoadBalancers[].DNSName" --output text)
curl -s http://$EXTERNAL_ALB_DNS/users/user123 -X PUT -H "Content-Type: application/json" -d '{"Name": "Jane Doe", "SkillLevel": "Advanced"}'
echo

echo =====5-5=====
EXTERNAL_ALB_DNS=$(aws elbv2 describe-load-balancers --names skills-consumer-alb --query "LoadBalancers[].DNSName" --output text)
curl -s http://$EXTERNAL_ALB_DNS/users/user123 -X DELETE
echo

echo =====6-1=====
aws dynamodb describe-table --table-name "skills-app-table" --query "Table.TableStatus"
echo

echo =====6-2=====
aws dynamodb describe-table --table-name "skills-app-table" --query "Table.BillingModeSummary.BillingMode"
echo

echo =====6-3=====
aws dynamodb describe-table --table-name "skills-app-table" --query "Table.DeletionProtectionEnabled"
echo
