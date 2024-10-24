$pwdinput = Read-Host "Enter the string of numbers for pwdLastSet"
$pwdLastSet = $pwdinput
[datetime]::FromFileTime($pwdLastSet)