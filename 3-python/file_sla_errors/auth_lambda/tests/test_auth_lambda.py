import os
import json
import boto3
from moto import mock_aws
from auth_lambda.auth_lambda import lambda_handler

# Get the default region from env variables
testRegion = os.environ['AWS_DEFAULT_REGION']


@mock_aws
def test_auth_lambda():
    # Set up Cognito mock
    client = boto3.client('cognito-idp', region_name=testRegion)
    user_pool_id = client.create_user_pool(PoolName='test_pool')['UserPool']['Id']
    client_id = client.create_user_pool_client(UserPoolId=user_pool_id, ClientName='test_client')['UserPoolClient']['ClientId']

    # Set the user pool ID environment variable
    os.environ['COGNITO_USER_POOL_ID'] = user_pool_id
    os.environ['COGNITO_CLIENT_ID'] = client_id

    # Create a test user
    client.admin_create_user(
        UserPoolId=user_pool_id,
        Username='test_user',
        UserAttributes=[
            {'Name': 'email', 'Value': 'test_user@example.com'}
        ],
        MessageAction='SUPPRESS'  # Prevents sending a welcome message
    )
    client.admin_set_user_password(
        UserPoolId=user_pool_id,
        Username='test_user',
        Password='Test@1234',
        Permanent=True
    )

    event = {
        'body': json.dumps({'username': 'test_user', 'password': 'Test@1234'})
    }
    response = lambda_handler(event, None)
    assert response['statusCode'] == 200, f"Expected status code 200 but got {response['statusCode']}. Response body: {response['body']}"
    assert 'token' in json.loads(response['body'])


@mock_aws
def test_auth_lambda_invalid_credentials():
    # Set up Cognito mock
    client = boto3.client('cognito-idp', region_name=testRegion)
    user_pool_id = client.create_user_pool(PoolName='test_pool')['UserPool']['Id']
    client_id = client.create_user_pool_client(UserPoolId=user_pool_id, ClientName='test_client')['UserPoolClient']['ClientId']

    # Set the user pool ID environment variable
    os.environ['COGNITO_USER_POOL_ID'] = user_pool_id
    os.environ['COGNITO_CLIENT_ID'] = client_id

    event = {
        'body': json.dumps({'username': 'wrong_user', 'password': 'wrong_password'})
    }
    response = lambda_handler(event, None)
    assert response['statusCode'] == 401, f"Expected status code 401 but got {response['statusCode']}. Response body: {response['body']}"
    assert 'message' in json.loads(response['body'])
