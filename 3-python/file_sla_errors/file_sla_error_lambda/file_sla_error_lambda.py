import json
import logging
import os
import uuid
from datetime import datetime, timezone
import boto3
import requests
from jose import jwt, JWTError

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource('dynamodb')
cloudwatch_client = boto3.client('cloudwatch')
table_name = os.environ['DYNAMODB_TABLE']
region = os.environ['AWS_DEFAULT_REGION']


def get_issuer():
    cognito_user_pool_id = os.environ['COGNITO_USER_POOL_ID']
    issuer = f'https://cognito-idp.{region}.amazonaws.com/{cognito_user_pool_id}'
    return issuer


def get_jwks():
    jwks_url = f'{get_issuer()}/.well-known/jwks.json'
    response = requests.get(jwks_url)
    response.raise_for_status()
    return response.json()


def lambda_handler(event, context):
    # Extract and validate JWT token
    headers = event['headers']
    auth_header = headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        logger.error("Authorization header missing or invalid")
        cloudwatch_client.put_metric_data(
            Namespace='FileSlaErrors',
            MetricData=[
                {
                    'MetricName': 'UnauthorizedRequests',
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
            'statusCode': 401,
            'body': json.dumps({'message': 'Unauthorized'})
        }
    
    token = auth_header.split(' ')[1]
    try:
        jwks = get_jwks()
        # Validate the JWT token
        jwt_options = {
            'verify_aud': False,  # Do not validate the audience
            'verify_exp': True,   # Validate the expiration
            'verify_iss': True    # Validate the issuer
        }
        claims = jwt.decode(token, jwks, options=jwt_options, issuer=get_issuer())
    except JWTError as e:
        logger.error(f"Invalid token: {str(e)}")
        cloudwatch_client.put_metric_data(
            Namespace='FileSlaErrors',
            MetricData=[
                {
                    'MetricName': 'InvalidTokens',
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
            'statusCode': 401,
            'body': json.dumps({'message': 'Invalid token'})
        } 
    except requests.exceptions.RequestException as e:
        logger.error(f"Error fetching JWKS: {str(e)}")
        cloudwatch_client.put_metric_data(
            Namespace='FileSlaErrors',
            MetricData=[
                {
                    'MetricName': 'JWKSFetchErrors',
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
            'statusCode': 500,
            'body': json.dumps({'message': 'Internal server error', 'error': str(e)})
        }
    
    # Extract data from request body
    try:
        body = json.loads(event['body'])
        sla_errors = body['sla_error']
    except (json.JSONDecodeError, KeyError) as e:
        logger.error(f"Bad request: {str(e)}")
        cloudwatch_client.put_metric_data(
            Namespace='FileSlaErrors',
            MetricData=[
                {
                    'MetricName': 'BadRequest',
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
            'statusCode': 400,
            'body': json.dumps({'message': 'Bad request'})
        }
    
    # Process and store data in DynamoDB
    table = dynamodb.Table(table_name)
    try:
        for error in sla_errors:
            folder = error['folder']
            sla = error['sla']
            files = error['files']
            affected_date = datetime.now(timezone.utc).isoformat()
            
            for file in files:
                item = {
                    'ErrorID': str(uuid.uuid4()),
                    'Folder': folder,
                    'AffectedDate': affected_date,
                    'SLA': sla,
                    'Filename': file['filename'],
                    'CreationDate': file['creationDate'],
                }
                table.put_item(Item=item)
        cloudwatch_client.put_metric_data(
            Namespace='FileSlaErrors',
            MetricData=[
                {
                    'MetricName': 'SuccessfulProcess',
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
    except Exception as e:
        logger.error(f"Error storing data in DynamoDB: {str(e)}")
        cloudwatch_client.put_metric_data(
            Namespace='FileSlaErrors',
            MetricData=[
                {
                    'MetricName': 'DynamoDBErrors',
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
            'statusCode': 500,
            'body': json.dumps({'message': 'Internal server error', 'error': str(e)})
        }
    
    return {
        'statusCode': 200,
        'body': json.dumps({'message': 'Data successfully processed'})
    }
