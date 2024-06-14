# Part 1 of the Coding Test: PowerShell

## Solution:
### SLA Monitoring PowerShell Script
#### Overview

This PowerShell script is designed to monitor folders for file processing based on specified Service Level Agreements (SLAs). The script checks if files in the designated folders have exceeded their SLA and reports the violations to a specified REST endpoint.

#### Features
- Monitors multiple folders for SLA violations.
- Configurable SLAs for each folder.
- Sends details of SLA violations to a REST endpoint as a JSON payload.
- Includes error handling for HTTP responses.
- Utilizes an external REST endpoint for authentication and authorization using a JWT token.

#### Requirements
- PowerShell 5.1 or later (To check your version use the command: `$PSVersionTable.PSVersion`)
- Internet connection for making REST API calls
- Authentication credentials (username and password) stored in environment variables

#### Usage
##### Configuration
- Set Environment Variables:
 
    `API_USERNAME`: Your username for authentication.

    `API_PASSWORD`: Your password for authentication.

Example:
```PowerShell
[System.Environment]::SetEnvironmentVariable("API_USERNAME", "your_username", "Machine")
[System.Environment]::SetEnvironmentVariable("API_PASSWORD", "your_password", "Machine")
```
- Define Paths: Ensure the *`$workFoldersPath`* and *`$logFile`* variables point to the correct directories for your environment.

- Define SLAs: Modify the *`$folders`* hashtable to set the SLAs for each folder in minutes.
  
- Define external API endpoints: Modify the *`$authEndpoint`* and *`$restEndpoint` variables to point to the correct URLs for your AWS environment (not necessary when running local tests).

##### Running the Script
- Execute the main script in PowerShell:
```PowerShell
.\Check-SLA.ps1
```

##### Additional Scripts
- Execute the following script in PowerShell to create a scheduled task that runs the `Check-SLA.ps1` PowerShell script every 10 minutes. To run this script, open PowerShell as an administrator.
```PowerShell
.\Create-ScheduledTask.ps1
```

- Execute the following script in PowerShell to remove the scheduled task created with the script mentioned above. To run this script, open PowerShell as an administrator.
```PowerShell
.\Remove-ScheduledTask.ps1
```

#### Notes
- Ensure that the folders you want to monitor exist and are accessible by the script.
- Adjust the SLAs according to your specific requirements.
- The script logs all activities and errors to a log file located in the `log` directory.

#### Troubleshooting
- **Authentication Issues:** Ensure that the environment variables for API_USERNAME and API_PASSWORD are correctly set and accessible by the script.
- **HTTP Errors:** Check the logs for detailed error messages and ensure that the REST endpoints are reachable.
- **Folder Access:** Ensure that the script has the necessary permissions to access and read the folders being monitored.

---

## Coding Test Definition:
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
