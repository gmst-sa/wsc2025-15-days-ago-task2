#!/bin/bash

# Export
aws configure set default.region ap-northeast-2
aws configure set default.output json

echo =====1-1-A=====
aws dynamodb describe-table --table-name account-table --query "Table.TableName" --output text
aws dynamodb describe-table --table-name account-table --query "Table.Replicas[].RegionName" --output text
aws dynamodb describe-continuous-backups --table-name account-table --query "ContinuousBackupsDescription.PointInTimeRecoveryDescription.PointInTimeRecoveryStatus" --output text
echo

echo =====1-2-A=====
aws lambda get-function --function-name account-conflict-resolver --query "Configuration.FunctionName" --output text
echo

echo =====1-3-A=====
APP_SRV_PUBLIC_IP=$(aws ec2 describe-instances --filter Name=tag:Name,Values=account-app-ec2 --query "Reservations[].Instances[].PublicIpAddress" --output text)

ACCOUNT_ID_V1="id-$RANDOM"
ACCOUNT_ID_V2="id-$RANDOM"
BALANCE1=$(shuf -i 1-10000 -n 1)
BALANCE2=$(shuf -i 1-10000 -n 1)
CURRENCY1=$(shuf -e USD EUR KRW -n 1)
CURRENCY2=$CURRENCY1

curl -s -X POST "$APP_SRV_PUBLIC_IP:8080/create_account" \
  -H "Content-Type: application/json" \
  -d "{\"account_id\": \"$ACCOUNT_ID_V1\", \"balance\": $BALANCE1, \"currency\": \"$CURRENCY1\"}"

echo

curl -s -X POST "$APP_SRV_PUBLIC_IP:8080/create_account" \
  -H "Content-Type: application/json" \
  -d "{\"account_id\": \"$ACCOUNT_ID_V2\", \"balance\": $BALANCE2, \"currency\": \"$CURRENCY2\"}"

echo

echo =====1-4-A=====
aws dynamodb get-item \
  --table-name account-table \
  --region ap-northeast-2 \
  --key "{\"account_id\": {\"S\": \"$ACCOUNT_ID_V1\"}}" --query '{account_id: Item.account_id.S, balance: Item.balance.N, currency: Item.currency.S}'

aws dynamodb get-item \
  --table-name account-table \
  --region ap-northeast-2 \
  --key "{\"account_id\": {\"S\": \"$ACCOUNT_ID_V2\"}}" --query '{account_id: Item.account_id.S, balance: Item.balance.N, currency: Item.currency.S}'
echo

echo =====1-5-A=====
ACCOUNT_ID_V3="id-$RANDOM"
BALANCE1=$(shuf -i 1-10000 -n 1)
BALANCE2=$(shuf -i 1-10000 -n 1)
CURRENCY=$(shuf -e USD EUR KRW -n 1)
echo "ap-northeast-2 balance: $BALANCE1"
echo "eu-central-1 balance: $BALANCE2"

aws dynamodb update-item \
  --table-name account-table \
  --region ap-northeast-2 \
  --key "{\"account_id\": {\"S\": \"$ACCOUNT_ID_V3\"}}" \
  --update-expression "SET balance = :b, currency = :c" \
  --expression-attribute-values "{\":b\": {\"N\": \"$BALANCE1\"}, \":c\": {\"S\": \"$CURRENCY\"}}"

aws dynamodb update-item \
  --table-name account-table \
  --region eu-central-1 \
  --key "{\"account_id\": {\"S\": \"$ACCOUNT_ID_V3\"}}" \
  --update-expression "SET balance = :b, currency = :c" \
  --expression-attribute-values "{\":b\": {\"N\": \"$BALANCE2\"}, \":c\": {\"S\": \"$CURRENCY\"}}"

sleep 30

aws dynamodb get-item \
  --table-name account-table \
  --region ap-northeast-2 \
  --key "{\"account_id\": {\"S\": \"$ACCOUNT_ID_V3\"}}" --query '{account_id: Item.account_id.S, balance: Item.balance.N, currency: Item.currency.S}'

aws dynamodb get-item \
  --table-name account-table \
  --region eu-central-1 \
  --key "{\"account_id\": {\"S\": \"$ACCOUNT_ID_V3\"}}" --query '{account_id: Item.account_id.S, balance: Item.balance.N, currency: Item.currency.S}'
echo