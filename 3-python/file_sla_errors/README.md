# Part 3 of the Coding Test: Python

## Solution:
### AWS Serverless File SLA Error Processing
#### Overview

This project consists of two AWS Lambda functions, `auth_lambda` and `file_sla_error_lambda`, designed to handle user authentication and file SLA error processing, respectively. The solution utilizes AWS Cognito for user authentication and DynamoDB for storing SLA error data. The Python scripts are tested using `pytest` with `moto` for mocking AWS services.

#### Components

##### 1. `auth_lambda`
This Lambda function handles user authentication using AWS Cognito. It validates the provided username and password, returning a JWT token upon successful authentication.

###### File Structure
```
auth_lambda/
├── __init__.py
├── auth_lambda.py
├── requirements.txt
└── tests/
    ├── __init__.py
    └── test_auth_lambda.py
```

###### `auth_lambda.py`
The main Lambda function for user authentication:
- Creates a Cognito user pool and client.
- Authenticates users and returns a JWT token.

###### `test_auth_lambda.py`
Unit tests for the `auth_lambda` function:
- Mocks AWS Cognito services.
- Tests valid and invalid authentication scenarios.

##### 2. `file_sla_error_lambda`
This Lambda function processes file SLA errors, validates JWT tokens, and stores error data in DynamoDB.

###### File Structure
```
file_sla_error_lambda/
├── __init__.py
├── file_sla_error_lambda.py
├── requirements.txt
└── tests/
    ├── __init__.py
    └── test_file_sla_error_lambda.py
```

###### `file_sla_error_lambda.py`
The main Lambda function for processing file SLA errors:
- Validates JWT tokens using AWS Cognito's JWKS endpoint.
- Processes and stores SLA error data in DynamoDB.

###### `test_file_sla_error_lambda.py`
Unit tests for the `file_sla_error_lambda` function:
- Mocks AWS DynamoDB and Cognito services.
- Tests valid and invalid token scenarios.

#### Dependencies

Ensure the following dependencies are included in your `requirements.txt` files:

**auth_lambda/requirements.txt**
```plaintext
boto3
botocore
moto
python-jose
pytest
```

**file_sla_error_lambda/requirements.txt**
```plaintext
boto3
botocore
moto
python-jose
pytest
requests
```

#### Environment Variables

The environment variables required for both Lambdas are set in `pytest.ini` for testing purposes.

**pytest.ini**
```ini
[pytest]
env =
    AWS_DEFAULT_REGION=us-east-1
    COGNITO_USER_POOL_ID=test_user_pool_id
    COGNITO_CLIENT_ID=test_client_id
    COGNITO_CLIENT_SECRET=test_client_secret
    AWS_ACCESS_KEY_ID=test_access_key
    AWS_SECRET_ACCESS_KEY=test_secret_key
    DYNAMODB_TABLE=FileSlaErrors
```

#### Testing

Unit tests are written using `pytest` and `moto` to mock AWS services. Follow the steps below to run the tests:

1. **Set Up Virtual Environment**

```bash
python -m venv venv
source venv/bin/activate  # On Windows use `venv\Scripts\activate`
```

2. **Install Dependencies**

```bash
pip install -r auth_lambda/requirements.txt
pip install -r file_sla_error_lambda/requirements.txt
```

3. **Run Tests**

```bash
# Navigate to the auth_lambda directory and run tests
cd auth_lambda
pytest tests/

# Navigate to the file_sla_error_lambda directory and run tests
cd ../file_sla_error_lambda
pytest tests/
```

#### Deployment

To deploy the Lambdas, use the provided `deploy.sh` script in the `deploy` directory, which packages and uploads the Lambda functions to AWS.

Ensure you have the necessary IAM permissions and AWS CLI configured before running the deployment script.

#### Conclusion

This project demonstrates a serverless architecture using AWS Lambda, Cognito, and DynamoDB to handle user authentication and file SLA error processing. The solution is tested using `pytest` and `moto`.

---

## Coding Test Definition:
The python must match the AWS Design and the input from the Powershell will be the expected input into the lambda function.

### Requirements

- Must be written in Python.
- Must 'write' to a DynamoDB.
- Response must be _200_ for successes, _400s_ for user error, and _500_ for internal system issues.
- Assume the _lambda_handler(event, context)_ is your entrypoint.
- Code must utilize the _boto3_ SDK.
- Write unit tests with _moto_.

**NOTE:** This will be executed locally, writing unit tests using moto will let us execute locally so we can talk through scenarios.