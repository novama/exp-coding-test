import json
import boto3
import os
from datetime import datetime
import logging

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

client = boto3.client('cognito-idp')
cloudwatch_client = boto3.client('cloudwatch')


def lambda_handler(event, context):
    try:
        cognito_user_pool_id = os.environ['COGNITO_USER_POOL_ID']
        client_id = os.environ['COGNITO_CLIENT_ID']

        body = json.loads(event['body'])
        username = body.get('username')
        password = body.get('password')

        if not username or not password:
            logger.error("Username or password not provided")
            return {
                'statusCode': 400,
                'body': json.dumps({'message': 'Username and password are required'})
            }

        # Initiate auth with Cognito
        response = client.admin_initiate_auth(
            UserPoolId=cognito_user_pool_id,
            ClientId=client_id,
            AuthFlow='ADMIN_NO_SRP_AUTH',
            AuthParameters={
                'USERNAME': username,
                'PASSWORD': password
            }
        )

        # Retrieve the token from the authentication response
        token = response['AuthenticationResult']['IdToken']
        
        # Log successful authentication metric
        cloudwatch_client.put_metric_data(
            Namespace='FileSlaErrors',
            MetricData=[
                {
                    'MetricName': 'SuccessfulAuth',
                    'Dimensions': [
                        {
                            'Name': 'FunctionName',
                            'Value': context.function_name
                        }
                    ],
                    'Timestamp': datetime.utcnow(),
                    'Value': 1,
                    'Unit': 'Count'
                }
            ]
        )

        return {
            'statusCode': 200,
            'body': json.dumps({'token': token})
        }
    except client.exceptions.NotAuthorizedException:
        logger.error("Not authorized exception")
        return {
            'statusCode': 401,
            'body': json.dumps({'message': 'Unauthorized'})
        }
    except client.exceptions.UserNotFoundException:
        logger.error("User not found exception")
        return {
            'statusCode': 401,
            'body': json.dumps({'message': 'User does not exist'})
        }
    except Exception as e:
        logger.error(f"Internal server error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'message': 'Internal server error', 'error': str(e)})
        }
