#!/bin/bash
# Set profile (PROFILENAME -- onetrace) and mfa code (TOKEN)
read -p "Profile (onetrace): " PROFILENAME
PROFILENAME=${PROFILENAME:-onetrace}
read -p "MFA Code: " TOKEN
clear

# Change these to match your AWS account IDs and IAM user names
SERIAL='arn:aws:iam::<account_id>:mfa/<iam_user_name>'

echo -e "\e[0;107m\e[1;30mConfiguring profile '$PROFILENAME' with mfa '$TOKEN'\e[0m"
CREDJSON="$(aws sts get-session-token --serial-number $SERIAL --profile $PROFILENAME --token-code $TOKEN)"

# End script if error encountered
if [ -z "$CREDJSON" ]; then
  echo
  echo "Something went wrong =("
  exit 126;
else
  echo $CREDJSON
fi

ACCESSKEY="$(echo $CREDJSON | jq '.Credentials.AccessKeyId' | sed 's/"//g')"
SECRETKEY="$(echo $CREDJSON | jq '.Credentials.SecretAccessKey' | sed 's/"//g')"
SESSIONTOKEN="$(echo $CREDJSON | jq '.Credentials.SessionToken' | sed 's/"//g')"
SESSIONPROFILE="$PROFILENAME"-session

clear

echo -e "\e[0;107m\e[1;30mUpdated Session Profile for $SESSIONPROFILE\e[0m"
echo
echo -e "\e[1;96mProfile:\e[0m $SESSIONPROFILE"
echo -e "\e[1;96mAccessKey:\e[0m $ACCESSKEY"
echo -e "\e[1;96mSecretKey:\e[0m $SECRETKEY"
echo -e "\e[1;96mSessionToken:\e[0m $SESSIONTOKEN"

aws configure set aws_access_key_id $ACCESSKEY --profile $SESSIONPROFILE
aws configure set aws_secret_access_key $SECRETKEY --profile $SESSIONPROFILE
aws configure set aws_session_token $SESSIONTOKEN --profile $SESSIONPROFILE

# Script for codeartifact and npm registry
echo
echo -e "\e[0;107m\e[1;30mConfiguring codeartifact login and set npm registry\e[0m"
echo
echo -e "\e[1;41m WARNING! \e[0m This will set your global .npmrc file to use onetrace registry; To revert to the default npm registry use this \e[0;93mnpm config set registry https://registry.npmjs.com/\e[0m"

ARTIFACTCONFIG="$(aws codeartifact login --tool npm --repository onetrace-artifacts --domain onetrace-domain --region eu-west-2 --profile onetrace-session)"

echo

# End script if error encountered
if [ -z "$ARTIFACTCONFIG" ]; then
  echo "Something went wrong =("
  exit 126;
else
  echo -e "\e[3;92m$ARTIFACTCONFIG\e[0m"
fi