# Notes: To run this script, open PowerShell as an administrator.
# This script will check if the scheduled task named "Check SLA Files" exists and remove it if it does.

# Define variables
$taskName = "Check SLA Files"

# Check if the task exists
$taskExists = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

if ($taskExists) {
    # Unregister the scheduled task
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    Write-Output "Scheduled task '$taskName' has been removed."
} else {
    Write-Output "Scheduled task '$taskName' does not exist."
}