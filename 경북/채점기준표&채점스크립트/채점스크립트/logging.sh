#!/bin/bash

aws configure set default.region eu-west-1

### 1. VPC/Subnet/RouteTable 점검

echo "===== 1-1 VPC CIDR 확인 ====="
aws ec2 describe-vpcs --filter Name=tag:Name,Values=skills-log-vpc --query "Vpcs[].CidrBlock"
echo

echo "===== 1-2 Subnet CIDR 확인 ====="
aws ec2 describe-subnets --filter Name=tag:Name,Values=skills-log-priv-a --query "Subnets[].CidrBlock"
aws ec2 describe-subnets --filter Name=tag:Name,Values=skills-log-priv-b --query "Subnets[].CidrBlock"
aws ec2 describe-subnets --filter Name=tag:Name,Values=skills-log-pub-a --query "Subnets[].CidrBlock"
aws ec2 describe-subnets --filter Name=tag:Name,Values=skills-log-pub-b --query "Subnets[].CidrBlock"
echo

echo "===== 1-3 Route Table 연결 확인 ====="
aws ec2 describe-route-tables --filter Name=tag:Name,Values=skills-log-priv-rt-a --query "RouteTables[].Routes[].NatGatewayId"
aws ec2 describe-route-tables --filter Name=tag:Name,Values=skills-log-priv-rt-b --query "RouteTables[].Routes[].NatGatewayId"
aws ec2 describe-route-tables --filter Name=tag:Name,Values=skills-log-pub-rt --query "RouteTables[].Routes[].GatewayId"
echo

### 2. Bastion EC2 점검

echo "===== 2-1 Bastion 인스턴스 타입 확인 ====="
aws ec2 describe-instances --filter Name=tag:Name,Values=skills-log-bastion --query "Reservations[].Instances[].InstanceType"
echo

### 3. ALB 점검

echo "===== 3-1 ALB 상태 및 DNS 확인 ====="
aws elbv2 describe-load-balancers --query "LoadBalancers[?contains(LoadBalancerName, 'skills-log-alb')].{DNSName:DNSName,Scheme:Scheme}"
echo

### 4. Application Health 확인

echo "===== 4-1 /check API 확인 ====="
ALB_DNS=$(aws elbv2 describe-load-balancers --names skills-log-alb --query "LoadBalancers[].DNSName" --output text)
curl -s http://$ALB_DNS/check
echo

### 5. ECR 점검

echo "===== 5-1 ECR 리포지토리 이름 및 취약점 스캔 확인 ====="
aws ecr describe-repositories --query "repositories[?repositoryName=='skills-app'].repositoryName"
aws ecr describe-repositories --query "repositories[?repositoryName=='skills-firelens'].repositoryName"
echo

### 6. ECS 클러스터 및 서비스 점검

echo "===== 6-1 ECS Cluster 상태 확인 ====="
aws ecs describe-clusters --clusters skills-log-cluster --query "clusters[0].status"
echo

echo "===== 6-2 ECS 서비스 상태 확인 ====="
aws ecs describe-services --cluster skills-log-cluster --services app --query "services[].status"
echo

echo "===== 6-3 ECS TaskDef 확인  ====="
aws ecs describe-task-definition --task-definition skills-log-app-td --query "taskDefinition.containerDefinitions[].name"
aws ecs describe-task-definition --task-definition skills-log-app-td --query "taskDefinition.containerDefinitions[].image"
echo

echo "===== 6-4 ECS Service Subnet 확인 ====="
aws ecs describe-services --cluster skills-log-cluster --services app --query "services[].networkConfiguration.awsvpcConfiguration[].subnets[]"
echo

### 7. FireLens Fluent Bit 설정 확인 (간접 확인)
echo "===== 7-1 FireLens 로그 드라이버 확인 ====="
aws ecs describe-task-definition --task-definition skills-log-app-td --query "taskDefinition.containerDefinitions[].logConfiguration.logDriver"
echo

### 8. CloudWatch 점검

echo "===== 8-1 CloudWatch Log 그룹 확인 ====="
aws logs describe-log-groups --log-group-name-prefix /skills/app --query "logGroups[].logGroupName"
echo

echo "===== 8-2 CloudWatch Log 스트림 확인 ====="
aws logs describe-log-streams --region eu-west-1 --log-group-name "/skills/app" --log-stream-name-prefix logs/$(aws ecs list-tasks --cluster skills-log-cluster --service-name app --desired-status RUNNING --region eu-west-1 --output text --query taskArns[0] | awk -F/ '{print $NF}') | jq -r '.logStreams[].logStreamName'
echo

echo "===== 8-3 CloudWatch Log 이벤트 확인 (2분 대기) ====="
curl http://$(aws elbv2 describe-load-balancers --names skills-log-alb --region eu-west-1 --query 'LoadBalancers[0].DNSName' --output text)/check
echo waiting for 2 minutes
sleep 120s
aws logs get-log-events --region eu-west-1 --log-group-name "/skills/app" --log-stream-name $(aws logs describe-log-streams --region eu-west-1 --log-group-name "/skills/app" --log-stream-name-prefix logs/$(aws ecs list-tasks --cluster skills-log-cluster --service-name app --desired-status RUNNING --region eu-west-1 --query 'taskArns[0]' --output text | awk -F/ '{print $NF}') --query 'logStreams[0].logStreamName' --output text) --limit 100 --no-start-from-head --query 'reverse(sort_by(events[?contains(message, `"/check"`)], &timestamp)) | [0].timestamp' --output text | grep -E '^[0-9]+$' | xargs -I{} bash -c 'date -u -d @$(expr {} / 1000) "+%Y-%m-%d %H:%M:%S"'
date -u '+%Y-%m-%d %H:%M:%S'
echo

