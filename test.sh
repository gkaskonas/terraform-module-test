export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

cd examples/basic-usage
tflocal init
tflocal apply -auto-approve
tflocal output