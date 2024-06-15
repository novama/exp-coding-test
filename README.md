# Coding Test

## Important Notes

- The basics of the code must be present, and the code must be in working order
- I care more about the design and architecture than ‘complete’ examples. If there is something convoluted or time consuming, just put a note in that 'X' needs to be considered
- You can use any technology available (Google, Stack Overflow, GPT, CoPilot, etc.) Just mention if you used them and how. We have access to GitHub CoPilot at Experian, so have at it!
- Testing is important to me; Please have unit tests
- ALL code must be auditable from a GitHub repository. All designs need to keep this in mind (no external configuration files to the source code)
- I care about architecture more than code. A good design is the foundation of good software. Most of our stack is lambda-based microservices… slightly messy code is forgivable when it is only a few hundred lines!
  - Still, have good comments and follow best practices around Unit Testing!

## Power Shell

We have folders that have files in them that move through the system as they process. A set of processes will move them to an 'archive' folder after they are processed. Sometimes, the processes die or slow down. Each folder has a specific SLA (20 minutes to 24 hours).

### Requirements:

- You need to create a powershell that will check a list of folders to see if their SLA has been tripped.
- The powershell needs to send all of the folders, and corresponding file names that have tripped to a REST endpoint.
- The request must be a JSON object that looks like:
```JSON
{
    "sla_error": [
        {
            "folder": string,
            "sla": int,
            "files": [{
                "filename": string,
                "creationDate": string
            }]
        }
    ]
}
```

**NOTE:** You can use a fake URL service to prove this works (POST [https://reqres.in/api/errorFolder](https://reqres.in/api/errorFolder)) to send data. It will always return a 200, but assume other errors an occur.


## AWS Design

We need to take data from the Powershell script above and ingest it into AWS. We need to process the data by saving it into a DynamoDB. We then need to do the following

### Requirements:
- Data received from the powershell must be passed to AWS.
- AWS serverless technologies are the only option for implementation.
- Must be authorized via a username/password. Design the authentication mechanism.
- Data must rest inside a DynamoDB.
- We also want to be able to search it by affected date and affected folder. Affected date is the more common use case.
- Must have metrics on how often the application is being used and what the HTTP status has returned.

**NOTE:** [https://www.drawio.com](https://www.drawio.com/) is a great free tool for diagramming. Feel free to use this.


## Python

The python must match the AWS Design and the input from the Powershell will be the expected input into the lambda function.

### Requirements

- Must be written in Python.
- Must 'write' to a DynamoDB.
- Response must be _200_ for successes, _400s_ for user error, and _500_ for internal system issues.
- Assume the _lambda_handler(event, context)_ is your entrypoint.
- Code must utilize the _boto3_ SDK.
- Write unit tests with _moto_.

**NOTE:** This will be executed locally, writing unit tests using moto will let us execute locally so we can talk through scenarios.
