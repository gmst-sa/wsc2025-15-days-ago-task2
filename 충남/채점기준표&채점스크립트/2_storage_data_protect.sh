#!/bin/bash

aws configure set region ap-northeast-2

echo --------------------
echo "       2-1        "
echo --------------------
aws s3api list-buckets --query "Buckets[?starts_with(Name, 'wsc2025-sensitive-')].Name" --output text

echo --------------------
echo "       2-2        "
echo --------------------
aws macie2 list-classification-jobs \
  --query "items[?name=='wsc2025-sensor-job'].name" \
  --output text

echo --------------------
echo "       2-3        "
echo --------------------
aws lambda list-functions \
  --query "Functions[?FunctionName=='wsc2025-masking-start'].FunctionName" \
  --output text

echo --------------------
echo "       2-4        "
echo --------------------
echo Manual

echo --------------------
echo "       2-5        "
echo --------------------
echo Manual

echo --------------------
echo "       2-6        "
echo --------------------
echo Manual

echo --------------------
echo "       2-7        "
echo --------------------
echo Manual