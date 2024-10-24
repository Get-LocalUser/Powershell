Connect-Entra -TenantId -Scopes 'User.ReadWrite.All' 
$passwordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
$passwordProfile.Password = Read-Host "Enter a strong password"
$userParams = @{
    DisplayName = Read-Host "Enter Display Name"
    PasswordProfile = $passwordProfile
    UserPrincipalName = Read-Host "Enter User Principal Name (e.g., user@domain.com)"
    AccountEnabled = $true
    MailNickName = Read-Host "Enter Mail Nickname"
}
New-EntraUser @userParams