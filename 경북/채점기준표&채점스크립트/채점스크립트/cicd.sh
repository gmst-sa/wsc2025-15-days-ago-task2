#!/bin/bash

aws configure set default.region eu-central-1

GITHUB_USER=$(gh api user --jq .login)

cd

echo =====1-1=====
for name in dev-vpc prod-vpc; do id=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$name" --query "Vpcs[0].VpcId" --output text); echo "$id $(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$id" --query "length(Subnets)" --output text)"; done
echo

echo =====2-1=====
for cluster in dev-cluster prod-cluster; do 
  subnets=($(aws eks describe-cluster --name $cluster --query "cluster.resourcesVpcConfig.subnetIds[]" --output text))
  subnet_count=${#subnets[@]}
  vpc_id=$(aws ec2 describe-subnets --subnet-ids ${subnets[0]} --query "Subnets[0].VpcId" --output text)
  vpc_name=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$vpc_id" "Name=key,Values=Name" --query "Tags[0].Value" --output text)
  public=false
  for s in "${subnets[@]}"; do 
    mp=$(aws ec2 describe-subnets --subnet-ids $s --query "Subnets[0].MapPublicIpOnLaunch" --output text)
    [[ "$mp" == "True" ]] && public=true && break
  done
  pub_status=$([ "$public" = true ] && echo "Public" || echo "Private")
  echo "$cluster $subnet_count $vpc_name $pub_status"
done
echo

echo =====2-2=====
kubectl get po -n app --output name | grep product
kubectl get runner -n app --output name
echo

echo =====2-3=====
argocd app list --output json | jq -r '.[] | [.metadata.name, .spec.sources[0].repoURL, .spec.source.repoURL] | @tsv'
echo

echo =====3-1=====
aws ecr describe-repositories --query "repositories[?repositoryName=='product/dev'||repositoryName=='product/prod'].repositoryName" --output text
echo

echo =====3-2=====
git clone --quiet https://github.com/${GITHUB_USER}/day2-product marking_product
cd marking_product

aws iam list-open-id-connect-providers \
  --query "OpenIDConnectProviderList[?contains(Arn, 'token.actions.githubusercontent.com')].Arn" \
  --output text

if grep -qE 'aws_access_key_id|aws_secret_access_key' .github/workflows/*.y*ml 2>/dev/null; then
  echo "warning!"
else
  echo "pass"
fi
echo
cd

echo =====4-1=====
gh repo list --limit 5 --json name,visibility --jq '.[] | "\(.name) (\(.visibility))"'
echo

echo =====4-2=====
gh api repos/"$GITHUB_USER"/day2-product/contents?ref=main | jq -r '.[].name'
echo

echo =====4-3=====
gh api repos/$GITHUB_USER/day2-product/contents/charts --jq '.[].name'
echo

echo =====4-4=====
gh api repos/"$GITHUB_USER"/day2-product/git/refs/heads --jq '.[] | select(.ref=="refs/heads/dev" or .ref=="refs/heads/prod") | .ref | sub("^refs/heads/";"")'
echo

echo =====4-5=====
gh repo view $GITHUB_USER/day2-product --json defaultBranchRef --jq '.defaultBranchRef.name'
echo

echo =====4-6=====
gh label list --repo $GITHUB_USER/day2-product | grep approval
echo

echo =====4-7=====
gh api repos/"$GITHUB_USER"/day2-product/contents/.github/workflows --jq '.[].name'
echo

echo =====4-8=====
gh api repos/"$GITHUB_USER"/day2-product/actions/runners --paginate --jq '.runners[] | select(any(.labels[].name; . == "dev" or . == "prod")) | "\(.name)\t\([.labels[].name] | join(","))"'
echo

echo =====5-1=====
export DEV_ALB_ENDPOINT=$(aws elbv2 describe-load-balancers --names dev-alb --query "LoadBalancers[0].DNSName" --output text)
curl -s "http://${DEV_ALB_ENDPOINT}/api"; echo
echo =============
echo

cd marking_product

git checkout dev > /dev/null 2> /dev/null
git pull origin dev > /dev/null 2> /dev/null

git checkout -b feature/marking-v2 > /dev/null 2> /dev/null

sed -i 's/product.*/product marking!\"/g' app.py

git add app.py > /dev/null 2> /dev/null
git commit -m "feat: product marking" > /dev/null 2> /dev/null

git push origin feature/marking-v2 > /dev/null 2> /dev/null

gh pr create --base dev --head feature/marking-v2 --title "Feat: product marking" --body "made with❤️"

echo =============
echo wait 1 minutes
echo
sleep 1m

export DEV_ALB_ENDPOINT=$(aws elbv2 describe-load-balancers --names dev-alb --query "LoadBalancers[0].DNSName" --output text)
curl -s "http://${DEV_ALB_ENDPOINT}/api"
echo
echo
cd

echo =====5-2=====
gh run list -R "$GITHUB_USER/day2-product" -w dev.yml --status completed --json startedAt,updatedAt --limit 1 -q '.[0] | ((.updatedAt|fromdateiso8601)-(.startedAt|fromdateiso8601))'
echo

echo =====5-3=====
aws ecr describe-images --repository-name product/dev --query 'sort_by(imageDetails,&imagePushedAt)[-1].[imageTags[0], imageManifestMediaType]' --output text | while read -r TAG MEDIA; do if [ "$MEDIA" = "application/vnd.oci.image.index.v1+json" ]; then TYPE="ImageIndex"; else TYPE="Image"; fi; printf "%s\t%s\n" "$TAG" "$TYPE"; done
echo

echo =====5-4=====
export PROD_ALB_ENDPOINT=$(aws elbv2 describe-load-balancers --names prod-alb --query "LoadBalancers[0].DNSName" --output text)
curl -s "http://${PROD_ALB_ENDPOINT}/api"; echo
echo =============
echo

cd marking_product

git checkout dev > /dev/null 2> /dev/null

gh pr create --base prod --head dev --title "Feat: product marking" --body "made with ❤️"

echo
echo "###############################################################################"
echo \# Proceed on https://github.com/${GITHUB_USER}/day2-product/pulls
echo "###############################################################################"
echo

while ! gh run list -R ${GITHUB_USER}/day2-product --status in_progress | grep -q "in_progress"; do sleep 1s; done;
echo =============
echo wait 1 minutes
echo
sleep 1m

export PROD_ALB_ENDPOINT=$(aws elbv2 describe-load-balancers --names prod-alb --query "LoadBalancers[0].DNSName" --output text)
curl -s "http://${PROD_ALB_ENDPOINT}/api"
echo
echo
cd

echo =====5-5=====
gh run list -R "$GITHUB_USER/day2-product" -w prod.yml --status completed --json startedAt,updatedAt --limit 1 -q '.[0] | ((.updatedAt|fromdateiso8601)-(.startedAt|fromdateiso8601))'
echo

echo =====5-6=====
aws ecr describe-images --repository-name product/prod --query 'sort_by(imageDetails,&imagePushedAt)[-1].[imageTags[0], imageManifestMediaType]' --output text | while read -r TAG MEDIA; do if [ "$MEDIA" = "application/vnd.oci.image.index.v1+json" ]; then TYPE="ImageIndex"; else TYPE="Image"; fi; printf "%s\t%s\n" "$TAG" "$TYPE"; done
echo
