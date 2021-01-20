#!/bin/bash

#
# ex) filename.sh <profile>

# check exist command aws.
if ! type "aws" > /dev/null 2>&1; then
    echo "aws command not installed."
    return;
fi
# check exist command jq.
if ! type "jq" > /dev/null 2>&1; then
    echo "jq command not installed."
    return;
fi

if [ $# = 1 ]; then
  profile=$1
else
  profile=default
fi

echo -e $profile

read -sp "Input MFA Code: " code

echo -e ""

device=$(aws configure get mfa_serial --profile "$profile")
echo -e "AWS Login MFA device: ${device}"
splits=(${device//:/ })
account=${splits[3]}
echo "AWS Login account: $account"

# execute get aws sts tokens. assume-role
sts=$(
  aws sts get-session-token \
  --serial-number "$device" \
  --token-code "$code" \
  --profile "$profile" \
  --duration-second 36000 \
  --output json
)

# set enviroment temporary aws access tokens
export AWS_ACCESS_KEY_ID=$(echo $sts | jq -r .Credentials.AccessKeyId)
export AWS_SECRET_ACCESS_KEY=$(echo $sts | jq -r .Credentials.SecretAccessKey)
export AWS_SESSION_TOKEN=$(echo $sts | jq -r .Credentials.SessionToken)
echo "AWS Access Key Id (AWS_ACCESS_KEY_ID)=$AWS_ACCESS_KEY_ID"

