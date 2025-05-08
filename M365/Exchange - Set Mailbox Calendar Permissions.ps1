<#
=============================================================================================
Name:           Exchange - Set Mailbox Calendar Permissions
Description:    Sets the permissions for users calendar.
Prerequisites:  ExchangeOnlineManagement Module

Script Tasks: 
~~~~~~~~~~~~~~~~~
1. Checks if module is installed and if not, installs it.
2. Conencts to Exchnage using admin account
3. Prompts for users or groups to have memberships.
============================================================================================
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$AdminEmail = '',

    [Parameter(Mandatory = $true)]
    [string]$UserEmail,

    [Parameter(Mandatory = $true)]
    [string]$Owner,

    [Parameter(Mandatory = $true)]
    [string]$PublishingEditor
)


# Check to see if run as adin, if not relaunch as admin
If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
    Write-Host "You didn't run this script as an Administrator. This script will self elevate to run as an Administrator and continue."
    Start-Sleep 1
    Start-Process Powershell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
    exit
}

# Import Exchange module or install if not present
$RequiredModule = Get-InstalledModule -Name ExchangeOnlineManagement
if (!$RequiredModule) {
        Install-Module -Name ExchangeOnlineManagement
    }
Import-Module -Name ExchangeOnlineManagement

# Connect to Exchange Online with admin account
try {
    Connect-ExchangeOnline -UserPrincipalName $AdminEmail -ShowBanner:$False -ErrorAction Stop
    Write-Host "Connected to Exchange Online successfully." -ForegroundColor Green
} catch {
    Write-Error "Failed to connect to Exchange Online: $_"
    exit 1
}

try {
    Set-MailboxFolderPermission -Identity "$($UserEmail):\calendar" -User default -AccessRights Reviewer
 
    Add-MailboxFolderPermission -Identity "$($UserEmail):\calendar" -User $Owner -AccessRights Owner
 
    Add-MailboxFolderPermission -Identity "$($UserEmail):\calendar" -User $PublishingEditor -AccessRights PublishingEditor
 
    Get-MailboxFolderPermission -Identity "$email`:\calendar"
}
catch {
    Write-Host "Failed to set a permission: $_"
}