<#
=============================================================================================
Name:           AD - Reset Password
Description:    Resets the selected users password.
Prerequisites:  Active Directory Module

Script Tasks: 
~~~~~~~~~~~~~~~~~
1. Prompts for the username and requires a yes or no to verify you have typed in the correct name.
2. Resets users password. 
============================================================================================
#>

function GetUsername {
    $Username = Read-Host -Prompt "Enter the username"
    $verify = Read-Host -Prompt "You entered '$Username'. Is this correct? Enter 'Yes' or 'No'"

    if ($verify -eq "Yes") {
        return $Username
    } else {
        Write-Host "You said 'No' Re-running."
        return GetUsername
    }
}
$Username = GetUsername

$NewPassword = Read-Host -Prompt "Enter new password here" -AsSecureString
Set-ADAccountPassword -Identity $Username -NewPassword $NewPassword -Reset
Set-ADUser -Identity $Username -PasswordNeverExpires $true -ChangePasswordAtLogon $false
Write-Host "Password reset for '$Username' is completed." -ForegroundColor Green