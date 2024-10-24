<#
=============================================================================================
Name:           AD - Get User
Description:    Retrieves the user from AD and displays preselected or all properties depending on choice and then asks if you'd like to see group memberships.
Prerequisites:  Active Directory Module

Script Tasks: 
~~~~~~~~~~~~~~~~~
1. Get's specified user
2. Gets the last time password was changed
3. Gives date when 90 days from password reset is up
4. Prompts for Group Membership retrieval.
============================================================================================
#>

param (
    [parameter(Mandatory=$true)]
    [string]$Identity,

    [parameter(Mandatory=$false)]
    [string[]]$objects = @('CN','employeeType','mail','StreetAddress', 'Enabled', 'LastLogonDate', 'LockedOut', 'pwdLastSet'),

    [parameter(Mandatory=$true)]
    [string]$Server = ''
)

# Get the user and their properties
function GetProperties {
    $question = Read-Host -Prompt "Type in 'Y' to retrieve all properties or 'N' to retrieve a preselected list"
    switch ($question.ToLower()) {
        'Y' {
            Get-ADUser -Identity $Identity -Properties * -Server $Server
          }
        'N' {
            Get-ADUser -Identity $Identity -Properties $objects -Server $Server
        }
        default {
            Write-Host "Invalid Input. Put in either Y or N." -ForegroundColor Red
            GetProperties
        }
    }
# Write the date and time of the last time the user reset their password    
$user = Get-ADUser -Identity $Identity -Properties $objects -Server $Server
$datetime = [datetime]::FromFileTime($user.pwdLastSet)
Write-Host "Password for '$Identity' last reset on $datetime" -ForegroundColor Cyan

# Count 90 days from $datetime
$datetimeplus90 = $datetime.AddDays(90)
Write-Host "90 days from the last password reset is $datetimePlus90" -ForegroundColor Cyan
}
GetProperties

# Retrieve the group memberships of the user
Start-Sleep -Seconds 3
$Memberships = Read-Host -Prompt "Would you like to get the users group memberships for on prem AD?"
if ($Memberships -match '^(Yes|y)$') {
    Get-ADUser -Identity $Identity -Properties MemberOf -Server $Server | Select-Object -ExpandProperty MemberOf
} else {
    Write-Host "You Selected '$Memberships' Script is finished." -ForegroundColor Yellow
}
