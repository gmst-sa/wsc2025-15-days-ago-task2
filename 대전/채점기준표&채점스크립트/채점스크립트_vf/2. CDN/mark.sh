#!/bin/bash

# Export
aws configure set default.region us-east-1
aws configure set default.output json

echo =====2-1-A=====
S3_BUCKET_NAME=$(aws s3api list-buckets --query "Buckets[?starts_with(Name, 'web-drm-bucket')].Name" --output text)

aws s3 ls $S3_BUCKET_NAME/ --recursive | awk '{print $4}'
echo

echo =====2-1-B=====
aws lambda list-functions --query "Functions[?FunctionName=='web-drm-function'].FunctionName" --output text
aws lambda get-function-configuration --function-name web-drm-function --region us-east-1 --query "Runtime" --output text
echo

echo =====2-1-C=====
aws resourcegroupstaggingapi get-resources --tag-filters Key=Name,Values=web-cdn --resource-type-filters 'cloudfront' --region us-east-1 --query "ResourceTagMappingList[0].ResourceARN" --output text | sed 's:.*/::' | xargs -I {} aws cloudfront get-distribution --id {} --query "Distribution.DomainName" --output text
echo

echo =====2-2-A=====
CLOUDFRONT_DISTRIBUTION_ID=$(aws resourcegroupstaggingapi get-resources --tag-filters Key=Name,Values=web-cdn --resource-type-filters 'cloudfront' --region us-east-1 --query "ResourceTagMappingList[0].ResourceARN" --output text | sed 's:.*/::')

aws cloudfront get-distribution --id $CLOUDFRONT_DISTRIBUTION_ID --query "Distribution.DistributionConfig.DefaultCacheBehavior.FunctionAssociations.Items[?contains(FunctionARN, 'web-cdn-function')].EventType" --output text
echo

echo =====2-3-A=====
aws cloudfront get-distribution --id $CLOUDFRONT_DISTRIBUTION_ID --query "Distribution.DistributionConfig.DefaultCacheBehavior.LambdaFunctionAssociations.Items[?contains(LambdaFunctionARN, 'web-drm-function')].EventType" --output text
echo

echo =====2-4-A=====
CLOUDFRONT_DNS=$(aws resourcegroupstaggingapi get-resources --tag-filters Key=Name,Values=web-cdn --resource-type-filters 'cloudfront' --region us-east-1 --query "ResourceTagMappingList[0].ResourceARN" --output text | sed 's:.*/::' | xargs -I {} aws cloudfront get-distribution --id {} --query "Distribution.DomainName" --output text)

curl -s -o /dev/null -w "%{http_code}\n" "https://$CLOUDFRONT_DNS/media/cloud.mp4"
echo
curl -s -o /dev/null -w "%{http_code}\n" "https://$CLOUDFRONT_DNS/media/fire.mp4"
echo
curl -s -o /dev/null -w "%{http_code}\n" "https://$CLOUDFRONT_DNS/media/mountain.mp4"
echo
curl -s -o /dev/null -w "%{http_code}\n" "https://$CLOUDFRONT_DNS/media/rain.mp4"
echo
curl -s -o /dev/null -w "%{http_code}\n" "https://$CLOUDFRONT_DNS/media/sea.mp4"
echo

echo =====2-5-A=====
curl -s -o /dev/null -w "%{http_code}\n" "https://$CLOUDFRONT_DNS/media/cloud.mp4?token=drm-it"
echo
curl -s -o /dev/null -w "%{http_code}\n" "https://$CLOUDFRONT_DNS/media/fire.mp4?token=drm-it"
echo
curl -s -o /dev/null -w "%{http_code}\n" "https://$CLOUDFRONT_DNS/media/mountain.mp4?token=drm-it"
echo
curl -s -o /dev/null -w "%{http_code}\n" "https://$CLOUDFRONT_DNS/media/rain.mp4?token=drm-it"
echo
curl -s -o /dev/null -w "%{http_code}\n" "https://$CLOUDFRONT_DNS/media/sea.mp4?token=drm-it"
echo

echo =====2-6-A=====
curl -s -o /dev/null -w "%{http_code}\n" "https://$CLOUDFRONT_DNS/media/cloud.mp4?token=drm-cloud"
echo
curl -s -o /dev/null -w "%{http_code}\n" "https://$CLOUDFRONT_DNS/media/fire.mp4?token=drm-cloud"
echo
curl -s -o /dev/null -w "%{http_code}\n" "https://$CLOUDFRONT_DNS/media/mountain.mp4?token=drm-cloud"
echo
curl -s -o /dev/null -w "%{http_code}\n" "https://$CLOUDFRONT_DNS/media/rain.mp4?token=drm-cloud"
echo
curl -s -o /dev/null -w "%{http_code}\n" "https://$CLOUDFRONT_DNS/media/sea.mp4?token=drm-cloud"
echo