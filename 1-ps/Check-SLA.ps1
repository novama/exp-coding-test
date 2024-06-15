<#
.SYNOPSIS
    This script checks a list of specified folders for SLA (Service Level Agreement) breaches.
    If any files in the folders exceed their designated SLA, the script logs the details and sends
    the information to a specified REST endpoint in JSON format.

.DESCRIPTION
    - The script defines a list of folders with their SLAs (in minutes).
    - It checks each folder for files that have exceeded their SLA by comparing the file creation time
      against the current time minus the SLA.
    - If SLA breaches are found, the script compiles the information into a JSON payload.
    - The payload is sent to a REST endpoint, with authentication handled via a JWT token.
    - Comprehensive logging is implemented to track the script's operations and any errors encountered.

.PARAMETER workFoldersPath
    The base path where the monitored folders are located.

.PARAMETER logFilePath
    The path to the log file where script operations and errors are logged.

.PARAMETER authEndpoint
    The REST endpoint for authentication to retrieve the JWT token.

.PARAMETER restEndpoint
    The REST endpoint to which SLA breach information is sent.

.PARAMETER username
    The username for authentication (default is retrieved from the API_USERNAME environment variable).

.PARAMETER password
    The password for authentication (default is retrieved from the API_PASSWORD environment variable).

.NOTES
    Ensure that the environment variables API_USERNAME and API_PASSWORD are set if not providing the parameters.

.EXAMPLE
    .\Check-SLA.ps1 -workFoldersPath "C:\MonitoredFolders" -logFilePath "C:\Logs\ps_logfile.log"
#>

# Define the parameters for the script
param (
    [string]$workFoldersPath,  # Update the default path as needed
    [string]$logFilePath,      # Update the default path as needed
    [string]$authEndpoint = "https://reqres.in/api/auth",
    [string]$restEndpoint = "https://reqres.in/api/errorFolder",
    [string]$username = [System.Environment]::GetEnvironmentVariable("API_USERNAME"),
    [string]$password = [System.Environment]::GetEnvironmentVariable("API_PASSWORD")
)

# Get script base directory
$baseDirectory = Split-Path -Parent $PSScriptRoot

# Define the parent path where all "monitored" folders with their SLAs are located
$defaultWorkFoldersPath = Join-Path -Path $baseDirectory -ChildPath "1-ps\sample_monitored_folders"

# Determine the log file path relative to the script location
$defaultLogFile = Join-Path -Path $baseDirectory -ChildPath "1-ps\log\ps_logfile.log"

# If param 'workFoldersPath' is not defined, use default.
if (-not ($workFoldersPath)) {
    $workFoldersPath = $defaultWorkFoldersPath
}

# If param 'logFilePath' is not defined, use default.
if (-not ($logFilePath)) {
    $logFilePath = $defaultLogFile
}

# Ensure log directory exists
$logDirectory = Split-Path -Path $logFilePath -Parent
if (-not (Test-Path -Path $logDirectory)) {
    New-Item -Path $logDirectory -ItemType Directory | Out-Null
}

# Define the list of folders with their SLAs in minutes
$folders = @{
    "Folder_A" = 20    # 20 minutes
    "Folder_B" = 40    # 40 minutes
    "Folder_C" = 60    # 60 minutes
    "Folder_D" = 1440  # 24 hours
}

# Log function
function Log-Message {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFilePath -Value "$timestamp - $message"
}

# Function to get JWT token
function Get-JWTToken {
    param (
        [string]$username,
        [string]$password
    )

    $authPayload = @{
        "username" = $username
        "password" = $password
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri $authEndpoint -Method Post -Body $authPayload -ContentType "application/json"
        return $response.token
    } catch {
        Log-Message "Failed to authenticate: $_"
        throw "Authentication failed"
    }
}

# Function to check files in a folder against the SLA
function Check-SLA {
    param (
        [string]$folder,
        [int]$sla
    )

    $currentDate = Get-Date
    $slaTime = (New-TimeSpan -Minutes $sla)
    $slaDate = $currentDate - $slaTime
    $errorFiles = @()

    # Ensure folder exists
    if (-not (Test-Path -Path $folder)) {
        Log-Message "Folder not found: $folder"
        return $null
    }

    Get-ChildItem -Path $folder -File | ForEach-Object {
        if ($_.CreationTime -lt $slaDate) {
            $errorFiles += [PSCustomObject]@{
                "filename" = $_.Name
                "creationDate" = $_.CreationTime.ToString("o") # ISO 8601 format
            }
        }
    }

    if ($errorFiles.Count -gt 0) {
        return @{
            "folder" = $folder
            "sla" = $sla
            "files" = $errorFiles
        }
    }
}

# List to hold all SLA errors
$slaErrors = @()

# Check each folder and accumulate SLA errors
foreach ($folderName in $folders.Keys) {
    $sla = $folders[$folderName]
    $folderPath = Join-Path -Path $workFoldersPath -ChildPath $folderName
    $result = Check-SLA -folder $folderPath -sla $sla
    if ($result) {
        $slaErrors += [PSCustomObject]$result
    }
}

# If there are SLA errors, send them to the REST endpoint
if ($slaErrors.Count -gt 0) {
    $payload = @{
        "sla_error" = $slaErrors
    } | ConvertTo-Json -Depth 5

    Log-Message "Request payload: $payload"

    try {
        # Get JWT token
        $token = Get-JWTToken -username $username -password $password

        # Send SLA errors with authorization header
        $headers = @{
            "Authorization" = "Bearer $token"
            "Content-Type" = "application/json"
        }

        $response = Invoke-RestMethod -Uri $restEndpoint -Method Post -Body $payload -Headers $headers

        Log-Message "SLA errors successfully reported. Response: $($response | ConvertTo-Json -Depth 5)"
    } catch {
        if ($_.Exception.Response.StatusCode -eq 400) {
            Log-Message "User error occurred while reporting SLA errors: $($_.Exception.Message)"
        } elseif ($_.Exception.Response.StatusCode -eq 500) {
            Log-Message "Internal server error occurred while reporting SLA errors: $($_.Exception.Message)"
        } else {
            Log-Message "An error occurred while reporting SLA errors: $_"
        }
    }
} else {
    Log-Message "No SLA errors found."
}
