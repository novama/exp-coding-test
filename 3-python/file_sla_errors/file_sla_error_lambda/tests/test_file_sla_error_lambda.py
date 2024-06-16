import json
import os
import boto3
from moto import mock_aws
from file_sla_error_lambda.file_sla_error_lambda import lambda_handler

# Get the default region from env variables
testRegion = os.environ['AWS_DEFAULT_REGION']


class MockContext:
    def __init__(self, function_name):
        self.function_name = function_name


@mock_aws
def test_file_sla_error_lambda():
    # Set up DynamoDB mock
    dynamodb = boto3.resource('dynamodb', region_name=testRegion)
    table_name = os.environ['DYNAMODB_TABLE']
    dynamodb.create_table(
        TableName=table_name,
        KeySchema=[{'AttributeName': 'ErrorID', 'KeyType': 'HASH'}],
        AttributeDefinitions=[{'AttributeName': 'ErrorID', 'AttributeType': 'S'}],
        ProvisionedThroughput={'ReadCapacityUnits': 5, 'WriteCapacityUnits': 5}
    )

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

    token = client.admin_initiate_auth(
        UserPoolId=user_pool_id,
        ClientId=client_id,
        AuthFlow='ADMIN_NO_SRP_AUTH',
        AuthParameters={'USERNAME': 'test_user', 'PASSWORD': 'Test@1234'}
    )['AuthenticationResult']['IdToken']

    event = {
        'headers': {
            'Authorization': f'Bearer {token}'
        },
        'body': json.dumps({
            'sla_error': [
                {
                    'folder': 'Folder_A',
                    'sla': 20,
                    'files': [
                        {'filename': 'file1.txt', 'creationDate': '2024-06-12T12:00:00Z'}
                    ]
                }
            ]
        })
    }
    context = MockContext(function_name='file_sla_error_lambda')
    response = lambda_handler(event, context)
    assert response['statusCode'] == 200, f"Expected status code 200 but got {response['statusCode']}. Response body: {response['body']}"
    
    # Verify data in DynamoDB
    table = dynamodb.Table(table_name)
    result = table.scan()
    assert len(result['Items']) == 1


@mock_aws
def test_file_sla_error_lambda_invalid_token():
    # Set up DynamoDB mock
    dynamodb = boto3.resource('dynamodb', region_name=testRegion)
    table_name = os.environ['DYNAMODB_TABLE']
    dynamodb.create_table(
        TableName=table_name,
        KeySchema=[{'AttributeName': 'ErrorID', 'KeyType': 'HASH'}],
        AttributeDefinitions=[{'AttributeName': 'ErrorID', 'AttributeType': 'S'}],
        ProvisionedThroughput={'ReadCapacityUnits': 5, 'WriteCapacityUnits': 5}
    )
    
    # Set up Cognito mock
    client = boto3.client('cognito-idp', region_name=testRegion)
    user_pool_id = client.create_user_pool(PoolName='test_pool')['UserPool']['Id']
    client_id = client.create_user_pool_client(UserPoolId=user_pool_id, ClientName='test_client')['UserPoolClient']['ClientId']

    # Set the user pool ID environment variable
    os.environ['COGNITO_USER_POOL_ID'] = user_pool_id
    os.environ['COGNITO_CLIENT_ID'] = client_id

    event = {
        'headers': {
            'Authorization': 'Bearer invalid_token'
        },
        'body': json.dumps({
            'sla_error': [
                {
                    'folder': 'Folder_A',
                    'sla': 20,
                    'files': [
                        {'filename': 'file1.txt', 'creationDate': '2024-06-12T12:00:00Z'}
                    ]
                }
            ]
        })
    }
    context = MockContext(function_name='file_sla_error_lambda')
    response = lambda_handler(event, context)
    assert response['statusCode'] == 401, f"Expected status code 401 but got {response['statusCode']}. Response body: {response['body']}"
