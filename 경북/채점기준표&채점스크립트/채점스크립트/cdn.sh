#!/bin/bash

export ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

aws configure set default.region ap-northeast-2

echo =====1-1=====
aws s3 ls s3://skills-kr-cdn-web-static-$ACCOUNT_ID/ --recursive | awk '{print $4}'
aws s3 ls s3://skills-us-cdn-web-static-$ACCOUNT_ID/ --recursive | awk '{print $4}'
echo

echo =====1-2=====
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
aws s3control list-multi-region-access-points \
  --account-id $ACCOUNT_ID \
  --region us-west-2
echo

echo =====2-1=====
aws ec2 describe-instances --filter Name=tag:Name,Values=mrap-bastion --query "Reservations[].Instances[].InstanceType"
echo

echo =====2-2=====
aws ec2 describe-instances --filter Name=tag:Name,Values=mrap-bastion --query "Reservations[].Instances[].PublicIpAddress"
aws ec2 describe-addresses --query "Addresses[].PublicIp"
echo

echo =====2-3=====
INSTANCE_NAME_TAG="mrap-bastion"
INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$INSTANCE_NAME_TAG" --query "Reservations[0].Instances[0].InstanceId" --output text)
AMI_ID=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query "Reservations[0].Instances[0].ImageId" --output text)
AMI_DESCRIPTION=$(aws ec2 describe-images --image-ids "$AMI_ID" --query "Images[0].Description" --output text)
INSTANCE_SG_NAME=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query "Reservations[0].Instances[0].SecurityGroups[0].GroupName" --output text)

echo "$AMI_DESCRIPTION"
echo "$INSTANCE_SG_NAME"
echo

echo =====2-4=====
POLICY_ARNS=$(aws iam list-attached-role-policies --role-name mrap-bastion-role --query "AttachedPolicies[].PolicyArn" --output text)
for POLICY_ARN in $POLICY_ARNS; do
POLICY_VERSION=$(aws iam get-policy --policy-arn $POLICY_ARN --query "Policy.DefaultVersionId" --output text)
POLICY_DOCUMENT=$(aws iam get-policy-version --policy-arn $POLICY_ARN --version-id $POLICY_VERSION --query "PolicyVersion.Document" --output json)
echo "$POLICY_DOCUMENT"
done
echo

echo =====3-1=====
aws resourcegroupstaggingapi get-resources --tag-filters Key=Name,Values=skills-global-distribution --resource-type-filters 'cloudfront' --region us-east-1 --query "ResourceTagMappingList[0].ResourceARN" --output text | sed 's:.*/::' | xargs -I {} aws cloudfront get-distribution --id {} --query "Distribution.DomainName"
echo

echo =====3-2=====
aws resourcegroupstaggingapi get-resources --tag-filters Key=Name,Values=skills-global-distribution --resource-type-filters 'cloudfront' --region us-east-1 --query "ResourceTagMappingList[0].ResourceARN" --output text | sed 's:.*/::' | xargs -I {} aws cloudfront get-distribution --id {} --query "Distribution.DistributionConfig.Origins.Items[*].DomainName" | grep "accesspoint.s3-global.amazonaws.com" | tr -d '[:space:]'
echo

echo =====3-3=====
aws resourcegroupstaggingapi get-resources --tag-filters Key=Name,Values=skills-global-distribution --resource-type-filters 'cloudfront' --region us-east-1 --query "ResourceTagMappingList[0].ResourceARN" --output text | sed 's:.*/::' | xargs -I {} aws cloudfront get-distribution --id {} --query "Distribution.DistributionConfig.PriceClass"
echo

echo =====3-4=====
aws cloudfront list-functions --region us-east-1 --query "FunctionList.Items[].{Name:Name, Stage:FunctionMetadata.Stage}" --output json
echo

echo =====4-1=====
aws lambda list-functions --region us-east-1 --query "Functions[].FunctionName" --output text
aws lambda list-functions --region ap-northeast-2 --query "Functions[].FunctionName" --output text
echo

echo =====4-2=====
aws lambda list-functions \
  --region us-east-1 \
  --query "Functions[?contains(Role, 'skills-lambda-role-us') || contains(Role, 'skills-lambda-role-us')].Role" \
  --output text | awk -F / '{print $NF}'
aws lambda list-functions \
  --region ap-northeast-2 \
  --query "Functions[?contains(Role, 'skills-lambda-role-kr') || contains(Role, 'skills-lambda-role-kr')].Role" \
  --output text | awk -F / '{print $NF}'
echo

echo =====5-1=====
CF_DOMAIN=$(aws resourcegroupstaggingapi get-resources --tag-filters Key=Name,Values=skills-global-distribution --resource-type-filters 'cloudfront' --region us-east-1 --query "ResourceTagMappingList[0].ResourceARN" --output text | sed 's:.*/::' | xargs -I {} aws cloudfront get-distribution --id {} --query "Distribution.DomainName" --output text)
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
echo "CloudFront Invalidation Test File 1" > test.html
aws s3 cp test.html s3://skills-kr-cdn-web-static-$ACCOUNT_ID/test.html
sleep 10
curl -L https://${CF_DOMAIN}/test.html
echo

echo =====5-2=====
CF_DOMAIN=$(aws resourcegroupstaggingapi get-resources --tag-filters Key=Name,Values=skills-global-distribution --resource-type-filters 'cloudfront' --region us-east-1 --query "ResourceTagMappingList[0].ResourceARN" --output text | sed 's:.*/::' | xargs -I {} aws cloudfront get-distribution --id {} --query "Distribution.DomainName" --output text)
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
echo "CloudFront Invalidation Test File 2" > test.html
aws s3 cp test.html s3://skills-kr-cdn-web-static-$ACCOUNT_ID/test.html
sleep 10
curl -L https://${CF_DOMAIN}/test.html
echo

echo =====6-1=====
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
us_east_1_bucket=skills-us-cdn-web-static-$ACCOUNT_ID
ap_northeast_2_bucket=skills-kr-cdn-web-static-$ACCOUNT_ID
mrap_arn=$(aws s3control list-multi-region-access-points \
  --account-id $ACCOUNT_ID \
  --query "AccessPoints[].Alias" \
  --region us-west-2 \
  --output text | awk -v acc=$ACCOUNT_ID '{print "arn:aws:s3::" acc ":accesspoint/" $1}')
TIMEFORMAT=%4R
dd if=/dev/urandom of=~/1MiB.file bs=1024 count=1024
echo =====us-east-1 버킷 직접 접근=====
for i in {1..2}; do 
    echo -n "Test $i: "
    time aws s3 cp ~/1MiB.file s3://$us_east_1_bucket/test-direct-$(date "+%Y%m%d-%H%M%S").file
    sleep 1
done
echo
echo =====ap-northeast-2 버킷 직접 접근=====
for i in {1..2}; do 
    echo -n "Test $i: "
    time aws s3 cp ~/1MiB.file s3://$ap_northeast_2_bucket/test-direct-$(date "+%Y%m%d-%H%M%S").file
    sleep 1
done
echo
echo =====mrap 접근=====
for i in {1..2}; do 
    echo -n "Test $i: "
    time aws s3 cp ~/1MiB.file s3://$mrap_arn/test-mrap-$(date "+%Y%m%d-%H%M%S").file
    sleep 1
done
echo
echo

echo =====7-1=====
echo "Sydney 리전 CloudShell에서 채점 (Country Block Check)"
echo

echo =====7-2=====
echo "Seoul 리전 CloudShell에서 채점 (Static Access Check - Seoul)"
echo

echo =====7-3=====
echo "N. Virginia 리전 CloudShell에서 채점 (Static Access Check - US)"
echo

echo =====7-4=====
echo "N. Virginia 리전 CloudShell에서 채점 (Header Block Check)"
echo
