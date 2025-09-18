#!/bin/bash

aws configure set region us-east-1
aws eks update-kubeconfig --name wsc2025-eks-cluster

echo --------------------
echo "       1-1        "
echo --------------------
aws ec2 describe-vpcs --filter Name=tag:Name,Values=wsc2025-hub-vpc --query "Vpcs[].CidrBlock"

echo --------------------
echo "       1-2        "
echo --------------------
aws ec2 describe-subnets \
  --filters "Name=tag:Name,Values=wsc2025-hub-pub-sn-a,wsc2025-hub-pub-sn-b" \
  --query "Subnets[*].[AvailabilityZone, CidrBlock]" \
  --output text

echo --------------------
echo "       1-3        "
echo --------------------  
aws ec2 describe-route-tables --filters "Name=tag:Name,Values=wsc2025-hub-pub-rt" \
  --query "RouteTables[*].{Name:Tags[?Key=='Name']|[0].Value}" --output text

echo --------------------
echo "       1-4        "
echo --------------------
aws ec2 describe-route-tables --filter Name=tag:Name,Values=wsc2025-hub-pub-rt \
    --query "RouteTables[].Routes[].GatewayId"

echo --------------------
echo "       1-5        "
echo --------------------
aws ec2 describe-vpcs --filter Name=tag:Name,Values=wsc2025-app-vpc --query "Vpcs[].CidrBlock"

echo --------------------
echo "       1-6        "
echo --------------------
aws ec2 describe-subnets \
  --filters "Name=tag:Name,Values=wsc2025-app-pub-sn-a,wsc2025-app-pub-sn-b,wsc2025-app-priv-sn-a,wsc2025-app-priv-sn-b,wsc2025-app-db-sn-a,wsc2025-app-db-sn-b" \
  --query "Subnets[*].[AvailabilityZone, CidrBlock]" \
  --output text

echo --------------------
echo "       1-7        "
echo --------------------  
aws ec2 describe-route-tables --filters "Name=tag:Name,Values=wsc2025-app-pub-rt, wsc2025-app-priv-rt-a, wsc2025-app-priv-rt-b, wsc2025-app-db-rt" \
  --query "RouteTables[*].{Name:Tags[?Key=='Name']|[0].Value}" --output text

echo --------------------
echo "       1-8        "
echo --------------------  
aws ec2 describe-route-tables \
  --filters "Name=tag:Name,Values=wsc2025-app-priv-rt-a,wsc2025-app-priv-rt-b" \
  --query "RouteTables[*].Routes[*].[NatGatewayId]" \
  --output text | grep ^nat-

echo --------------------
echo "       1-9        "
echo --------------------
aws ec2 describe-transit-gateways \
  --filters "Name=tag:Name,Values=wsc2025-tgw" \
  --query "TransitGateways[*].Tags[?Key=='Name'].Value[]" \
  --output text

echo --------------------
echo "       1-10       "
echo --------------------
aws ec2 describe-transit-gateway-attachments \
  --filters "Name=tag:Name,Values=wsc2025-app-tgat,wsc2025-hub-tgat" \
  --query "TransitGatewayAttachments[*].Tags[?Key=='Name'].Value[]" \
  --output text

echo --------------------
echo "       2-1        "
echo --------------------
aws eks describe-cluster --name wsc2025-eks-cluster --query 'cluster.[name, version]' --output text

echo --------------------
echo "       2-2        "
echo --------------------
aws eks describe-nodegroup --cluster-name wsc2025-eks-cluster --nodegroup-name wsc2025-app-ng \
  --query 'nodegroup.[nodegroupName, instanceTypes]' --output text
aws eks describe-nodegroup --cluster-name wsc2025-eks-cluster --nodegroup-name wsc2025-addon-ng \
  --query 'nodegroup.[nodegroupName, instanceTypes]' --output text

echo --------------------
echo "       2-3        "
echo --------------------
kubectl get nodes -o custom-columns=NAME:.metadata.name --no-headers

echo --------------------
echo "       2-4        "
echo --------------------
kubectl run tmp-curl --rm -i --tty \
  --image=debian --restart=Never \
  -- bash -c "apt update -y && apt install -y dnsutils && nslookup wsc2025-green-svc.wsc2025.svc.wsc2025.local"

echo --------------------
echo "       2-5        "
echo --------------------
aws ecr describe-repositories \
  --query "repositories[?repositoryName=='green'].repositoryName" \
  --output text

echo --------------------
echo "       2-6        "
echo --------------------
aws ecr describe-repositories \
  --query "repositories[?repositoryName=='red'].repositoryName" \
  --output text

echo --------------------
echo "       2-7        "
echo --------------------
aws ecr list-images \
  --repository-name green \
  --query "imageIds[].imageTag" \
  --output text | tr '\t' '\n' | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$'

echo --------------------
echo "       2-8        "
echo --------------------
aws ecr list-images \
  --repository-name red \
  --query "imageIds[].imageTag" \
  --output text | tr '\t' '\n' | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$'

echo --------------------
echo "       2-9        "
echo --------------------
kubectl get deployment wsc2025-green-deploy -n wsc2025 -o jsonpath="{.spec.template.spec.containers[*].name}" | grep -w wsc2025-green-app

echo --------------------
echo "       2-10       "
echo --------------------
kubectl get deployment wsc2025-red-deploy -n wsc2025 -o jsonpath="{.spec.template.spec.containers[*].name}" | grep -w wsc2025-red-app

echo --------------------
echo "       2-11       "
echo --------------------
kubectl get pods -l app=wsc2025-green-deploy -n wsc2025 -o wide \
  | awk 'NR>1 {print $7}' \
  | xargs -I{} kubectl get node {} -o jsonpath="{.metadata.labels['topology\.kubernetes\.io/zone']}" \
  | sort | uniq

kubectl get pods -l app=wsc2025-red-deploy -n wsc2025 -o wide \
  | awk 'NR>1 {print $7}' \
  | xargs -I{} kubectl get node {} -o jsonpath="{.metadata.labels['topology\.kubernetes\.io/zone']}" \
  | sort | uniq

echo --------------------
echo "       2-12       "
echo --------------------
aws elbv2 describe-load-balancers \
  --query "LoadBalancers[?LoadBalancerName=='wsc2025-app-alb'].[LoadBalancerName, Scheme]" \
  --output text

echo --------------------
echo "       2-13       "
echo --------------------
aws elbv2 describe-load-balancers \
  --query "LoadBalancers[?LoadBalancerName=='wsc2025-external-nlb'].[LoadBalancerName, Scheme]" \
  --output text

echo --------------------
echo "       3-1        "
echo --------------------
aws rds describe-db-instances \
  --query "DBInstances[?DBInstanceIdentifier=='wsc2025-db-instance'].[DBInstanceIdentifier, Engine]" \
  --output text

echo --------------------
echo "       3-2        "
echo --------------------
aws rds describe-db-instances \
  --query "DBInstances[?DBInstanceIdentifier=='wsc2025-db-instance'].MultiAZ" \
  --output text

echo --------------------
echo "       3-3        "
echo --------------------
export DB_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier wsc2025-db-instance \
  --query "DBInstances[0].Endpoint.Address" \
  --output text)
mysql -h $DB_ENDPOINT -u admin -pSkill53## -e "USE day1; SHOW TABLES;"

echo --------------------
echo "       3-4        "
echo --------------------
echo Manual

echo --------------------
echo "       3-5        "
echo --------------------
aws s3api list-buckets \
  --query "Buckets[].Name" \
  --output text | tr '\t' '\n' | grep -E '^wsc2025-app-[a-zA-Z0-9]{4}$'

echo --------------------
echo "       3-6        "
echo --------------------
export BUCKET_NAME=$(aws s3api list-buckets --query "Buckets[].Name" --output text | tr '\t' '\n' | grep -E '^wsc2025-app-[a-zA-Z0-9]{4}$')
for prefix in green red; do
  aws s3api list-objects-v2 \
    --bucket $BUCKET_NAME \
    --prefix source/$prefix/ \
    --query "Contents[].Key" \
    --output text
  echo ""
done

echo --------------------
echo "       4-1        "
echo --------------------
aws codebuild list-projects \
  --query "projects[?contains(@, 'wsc2025-green-build')]" \
  --output text

echo --------------------
echo "       4-2        "
echo --------------------
aws codebuild list-projects \
  --query "projects[?contains(@, 'wsc2025-red-build')]" \
  --output text

echo --------------------
echo "       4-3        "
echo --------------------
aws codepipeline list-pipelines \
  --query "pipelines[?name=='wsc2025-green-pipeline'].name" \
  --output text

echo --------------------
echo "       4-4        "
echo --------------------
aws codepipeline list-pipelines \
  --query "pipelines[?name=='wsc2025-red-pipeline'].name" \
  --output text

echo --------------------
echo "       4-5        "
echo --------------------
echo Manual

echo --------------------
echo "       4-6        "
echo --------------------
echo Manual

echo --------------------
echo "       4-7        "
echo --------------------
echo Manual

echo --------------------
echo "       4-8        "
echo --------------------
echo Manual

echo --------------------
echo "       4-9        "
echo --------------------
echo Manual

echo --------------------
echo "       4-10        "
echo --------------------
echo Manual