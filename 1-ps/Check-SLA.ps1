# Get script base directory
$baseDirectory = Split-Path -Parent $PSScriptRoot

# Define the parent path where all "monitored" folders with their SLAs are located
$workFoldersPath = Join-Path -Path $baseDirectory -ChildPath "1-ps\sample_monitored_folders"

# Determine the log file path relative to the script location
$logFile = Join-Path -Path $baseDirectory -ChildPath "1-ps\log\ps_logfile.log"

# Ensure log directory exists
$logDirectory = Split-Path -Path $logFile -Parent
if (-not (Test-Path -Path $logDirectory)) {
    New-Item -Path $logDirectory -ItemType Directory | Out-Null
}

# Define the list of folders with their SLAs in minutes
$folders = @{
    "Folder_A" = 20 # 20 minutes
    "Folder_B" = 40 # 40 minutes
    "Folder_C" = 60 # 60 minutes
    "Folder_D" = 1440 # 24 hours
}

# Define the REST endpoint URLs
$authEndpoint = "https://reqres.in/api/auth"
$restEndpoint = "https://reqres.in/api/errorFolder"

# Retrieve authentication credentials from environment variables
$username = [System.Environment]::GetEnvironmentVariable("API_USERNAME")
$password = [System.Environment]::GetEnvironmentVariable("API_PASSWORD")
# Before running the script, ensure that the environment variables 
# API_USERNAME and API_PASSWORD are set in your system.
# You can set these variables in PowerShell like this:
#[System.Environment]::SetEnvironmentVariable("API_USERNAME", "your_username", "Machine")
#[System.Environment]::SetEnvironmentVariable("API_PASSWORD", "your_password", "Machine")


# Log function
function Log-Message {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "$timestamp - $message"
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
