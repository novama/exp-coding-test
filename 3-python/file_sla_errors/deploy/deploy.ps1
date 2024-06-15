# Variables
$AUTH_LAMBDA_NAME = "auth_lambda"
$FILE_SLA_ERROR_LAMBDA_NAME = "file_sla_error_lambda"
$REGION = "your_region"
$DEPLOY_DIR = "../deploy"
$BUILD_DIR = "../build"

# Function to create deployment package
function Create-DeploymentPackage {
    param (
        [string]$LambdaName,
        [string]$SourceDir
    )

    # Create build directory
    $buildPath = "$BUILD_DIR\$LambdaName"
    New-Item -ItemType Directory -Force -Path $buildPath

    # Copy source files
    Copy-Item -Recurse -Force "$SourceDir\*" $buildPath

    # Install dependencies
    pip install -r "$SourceDir\requirements.txt" -t $buildPath

    # Create zip file
    $zipFilePath = "$DEPLOY_DIR\$LambdaName`_deploy.zip"
    if (Test-Path $zipFilePath) {
        Remove-Item -Force $zipFilePath
    }
    Compress-Archive -Path "$buildPath\*" -DestinationPath $zipFilePath

    # Remove build directory
    Remove-Item -Recurse -Force $buildPath
}

# Create deployment package for auth_lambda
Create-DeploymentPackage -LambdaName $AUTH_LAMBDA_NAME -SourceDir "../auth_lambda"

# Create deployment package for file_sla_error_lambda
Create-DeploymentPackage -LambdaName $FILE_SLA_ERROR_LAMBDA_NAME -SourceDir "../file_sla_error_lambda"

# Deploy auth_lambda
aws lambda update-function-code --function-name $AUTH_LAMBDA_NAME --zip-file fileb://"$DEPLOY_DIR/auth_lambda_deploy.zip" --region $REGION

# Deploy file_sla_error_lambda
aws lambda update-function-code --function-name $FILE_SLA_ERROR_LAMBDA_NAME --zip-file fileb://"$DEPLOY_DIR/file_sla_error_lambda_deploy.zip" --region $REGION

Write-Output "Deployment completed successfully."
