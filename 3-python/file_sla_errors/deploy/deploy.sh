#!/bin/bash

set -e

# Variables
AUTH_LAMBDA_NAME="auth_lambda"
FILE_SLA_ERROR_LAMBDA_NAME="file_sla_error_lambda"
REGION="your_region"
DEPLOY_DIR="../deploy"
BUILD_DIR="../build"

# Function to create deployment package
create_deployment_package() {
  local lambda_name=$1
  local source_dir=$2

  mkdir -p $BUILD_DIR/$lambda_name
  cp -r $source_dir/* $BUILD_DIR/$lambda_name/
  
  pip install -r $source_dir/requirements.txt -t $BUILD_DIR/$lambda_name/
  zip -r $DEPLOY_DIR/${lambda_name}_deploy.zip -j $BUILD_DIR/$lambda_name/*
  
  rm -rf $BUILD_DIR/$lambda_name
}

# Create deployment package for auth_lambda
create_deployment_package $AUTH_LAMBDA_NAME "../auth_lambda"

# Create deployment package for file_sla_error_lambda
create_deployment_package $FILE_SLA_ERROR_LAMBDA_NAME "../file_sla_error_lambda"

# Deploy auth_lambda
aws lambda update-function-code --function-name $AUTH_LAMBDA_NAME --zip-file fileb://$DEPLOY_DIR/auth_lambda_deploy.zip --region $REGION

# Deploy file_sla_error_lambda
aws lambda update-function-code --function-name $FILE_SLA_ERROR_LAMBDA_NAME --zip-file fileb://$DEPLOY_DIR/file_sla_error_lambda_deploy.zip --region $REGION

echo "Deployment completed successfully."
