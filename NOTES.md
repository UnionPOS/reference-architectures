# Notes

## running terraform from geodesic 

### assume root role

export TF_VAR_aws_assume_role_arn=""
unset AWS_DEFAULT_PROFILE
unset AWS_PROFILE

cd /conf/$(module)
direnv exec . make deps
direnv exec . terraform plan
direnv exec . terraform import module.prod.aws_organizations_account.default 731646523614

### assume bootstrap role

apk add --update assume-role@cloudposse
source /artifacts/.envrc
export HOME="/artifacts"
export AWS_CONFIG_FILE="${HOME}/.aws/config"
export AWS_SHARED_CREDENTIALS_FILE="${HOME}/.aws/credentials"
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
export AWS_ASSUME_ROLE_ARN=$(crudini --get ${AWS_CONFIG_FILE} "profile ${AWS_DEFAULT_PROFILE}" role_arn)
eval $(/usr/bin/assume-role $AWS_DEFAULT_PROFILE)
cd iam
direnv exec . make deps
direnv exec . terraform plan
