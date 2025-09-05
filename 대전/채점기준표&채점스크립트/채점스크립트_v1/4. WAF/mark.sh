#!/bin/bash

aws configure set region us-west-1

echo =====4-1-A=====
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=xxe-server" \
  --query "Reservations[].Instances[].{Name: Tags[?Key=='Name']|[0].Value, Type: InstanceType}" \
  --output text

echo =====4-2-A=====
aws elbv2 describe-load-balancers \
  --query "LoadBalancers[?contains(LoadBalancerName, 'xxe-alb')].[LoadBalancerName, Type]" \
  --output text

echo =====4-3-A=====
aws wafv2 list-web-acls \
  --scope REGIONAL \
  --query "WebACLs[?Name=='xxe-waf'].Name" \
  --output text

echo =====4-4-A=====
ENDPOINT=$(aws elbv2 describe-load-balancers \
  --names xxe-alb \
  --query "LoadBalancers[0].DNSName" \
  --output text)
curl -X POST http://$ENDPOINT/parse \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode $'xml=<?xml version="1.0"?>\n<user>\n  <username>testuser</username>\n  <email>test@example.com</email>\n</user>'

echo =====4-5-A=====
ENDPOINT=$(aws elbv2 describe-load-balancers \
  --names xxe-alb \
  --query "LoadBalancers[0].DNSName" \
  --output text)
curl -X POST http://$ENDPOINT/parse \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode $'xml=<?xml version="1.0"?>\n<!DOCTYPE root [\n<!ENTITY xxe SYSTEM "http://169.254.169.254/latest/meta-data/iam/">\n]>\n<root><data>&xxe;</data></root>'

echo =====4-6-A=====
ENDPOINT=$(aws elbv2 describe-load-balancers \
  --names xxe-alb \
  --query "LoadBalancers[0].DNSName" \
  --output text)
curl -X POST http://$ENDPOINT/parse \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode $'xml=<?xml version="1.0"?>\n<!DOCTYPE lolz [\n<!ENTITY lol "lol">\n<!ENTITY lol1 "&lol;&lol;&lol;&lol;&lol;&lol;&lol;&lol;&lol;&lol;">\n<!ENTITY lol2 "&lol1;&lol1;&lol1;&lol1;&lol1;&lol1;&lol1;&lol1;&lol1;&lol1;">\n<!ENTITY lol3 "&lol2;&lol2;&lol2;&lol2;&lol2;&lol2;&lol2;&lol2;&lol2;&lol2;">\n]>\n<root><boom>&lol3;</boom></root>'

echo =====A-7-A=====
ENDPOINT=$(aws elbv2 describe-load-balancers \
  --names xxe-alb \
  --query "LoadBalancers[0].DNSName" \
  --output text)
curl -X POST http://$ENDPOINT/parse \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode $'xml=<?xml version="1.0"?>\n<!DOCTYPE root [\n<!ENTITY xxe SYSTEM "file:///etc/passwd">\n]>\n<root><data>&xxe;</data></root>'