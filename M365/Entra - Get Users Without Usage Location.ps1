<#
=============================================================================================
Name:           Entra - Get Users Without Usage Location
Description:    Retrieves users in the tenant with no location set which will cause breaking in assigning a license
Prerequisites:  EntraID Module
Other:          Slight adjustment from MS's script https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.entra/get-entrauser?view=entra-powershell

Script Tasks: 
~~~~~~~~~~~~~~~~~
============================================================================================
#>


Connect-Entra -Scopes 'User.Read.All'
$EntraUsers = Get-EntraUser -All
$EntraUsersLocation = foreach ($User in $EntraUsers) {
    if ($User.usageLocation -eq $null) {
        [pscustomobject]@{
            Id                  = $user.Id
            DisplayName         = $user.DisplayName
            UserPrincipalName   = $user.UserPrincipalName
            usageLocation       = $user.usageLocation
        }
    }
}
$EntraUsersLocation | Format-Table Id, DisplayName, UserPrincipalName, usageLocation -AutoSize