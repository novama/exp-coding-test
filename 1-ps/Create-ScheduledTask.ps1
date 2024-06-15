<# 
.SYNOPSIS
    This script will create a scheduled task that runs the Check-SLA PowerShell script 
    every 60 minutes, with the settings specified. 
.NOTES
    - Adjust the script path and other settings as needed for your environment.
    - To run this script, open PowerShell as an administrator.
#>

# Get script base directory
$baseDirectory = Split-Path -Parent $PSScriptRoot

# Define variables
$taskName = "Check SLA Files"
$taskDescription = "Check SLA for folders and report errors"
$scriptPath = Join-Path -Path $baseDirectory -ChildPath "1-ps\Check-SLA.ps1" # Replace with the actual path to the script file in your system
$triggerInterval = 60 # in minutes

# Define the action to run the PowerShell script
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File `"$scriptPath`""

# Define the trigger to run the task every 10 minutes
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes $triggerInterval) -RepetitionDuration (New-TimeSpan -Days 1)

# Define the task settings
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew

# Create the scheduled task
Register-ScheduledTask -TaskName $taskName -Description $taskDescription -Action $action -Trigger $trigger -Settings $settings -User "SYSTEM" -RunLevel Highest