#!/bin/bash

aws configure set region eu-west-1

echo --------------------
echo "       4-1        "
echo --------------------
aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=wsc2025-egress-vpc,wsc2025-app-vpc" \
  --query "Vpcs[*].CidrBlock" \
  --output text

echo --------------------
echo "       4-2        "
echo --------------------
aws ec2 describe-subnets \
  --filters "Name=tag:Name,Values=wsc2025-egress-public-sn-a,wsc2025-egress-public-sn-b,wsc2025-egress-peering-sn-a,wsc2025-egress-peering-sn-b,wsc2025-egress-firewall-sn-a,wsc2025-egress-firewall-sn-b,wsc2025-app-private-sn-a,wsc2025-app-private-sn-b" \
  --query "Subnets[*].CidrBlock" \
  --output text

echo --------------------
echo "       4-3        "
echo --------------------
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=app-bastion" \
  --query "Reservations[*].Instances[*].Tags[?Key=='Name'].Value|[0]" \
  --output text

echo --------------------
echo "       4-4        "
echo --------------------
aws network-firewall describe-firewall \
  --firewall-name wsc2025-firewall \
  --query "[Firewall.FirewallName, Firewall.SubnetMappings[*].SubnetId]" \
  --output text

echo --------------------
echo "       4-5        "
echo --------------------
aws network-firewall list-rule-groups \
  --type STATELESS \
  --query "RuleGroups[*].Arn" \
  --output text
aws network-firewall list-rule-groups \
  --type STATEFUL \
  --query "RuleGroups[*].Arn" \
  --output text

echo --------------------
echo "       4-6        "
echo --------------------
aws network-firewall list-rule-groups \
  --type STATELESS \
  --query "RuleGroups[*].Arn" \
  --output text
aws network-firewall list-rule-groups \
  --type STATEFUL \
  --query "RuleGroups[*].Arn" \
  --output text

echo --------------------
echo "       4-7        "
echo --------------------
ping 1.1.1.1

echo --------------------
echo "       4-8        "
echo --------------------
nslookup google.com 8.8.8.8