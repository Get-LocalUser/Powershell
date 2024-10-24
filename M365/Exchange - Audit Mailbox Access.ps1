<#
=============================================================================================
Name:           Exchange - Audit Mailbox Access
Description:    Retrieves mailboxes that the specified user has access to.
Prerequisites:  ExchangeOnlineManagement Module

Script Tasks: 
~~~~~~~~~~~~~~~~~
See description^
============================================================================================
#>

# Import Exchange module or install if not present
try {
    Import-Module -Name ExchangeOnlineManagement -ErrorAction Stop
    Write-Host "Module imported succeessfully." -ForegroundColor Green
}
catch {
    Write-Host "Failed to import the module: $_"
    Write-Host "Attempting to install the Exchange PS module" -ForegroundColor Yellow
    try {
        Install-Module -Name ExchangeOnlineManagement -Scope CurrentUser -Force -ErrorAction Stop
        Import-Module -Name ExchangeOnlineManagement -ErrorAction Stop
        Write-Host "Module installed and imported successfully."
    }
    catch {
        Write-Host "Failed to install or import the module: $_"
        exit 1
    }
}

# Specify user to audit mailbox access for
$admin = Read-Host "Enter in your admin account e.g., john.doe@example.com"
$user = Read-Host "Enter the users account name, e.g., 'john.doe'"
Connect-ExchangeOnline -UserPrincipalName $admin -ShowBanner:$false
Get-Mailbox -ResultSize Unlimited | Get-MailboxPermission -User $user | Format-Table User,Identity,AccessRights