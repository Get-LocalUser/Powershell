
$accountfolders = Get-ChildItem -Path "C:\Users"
$join = @(Join-Path $accountfolders.FullName "AppData\Local\Temp")

Write-host "Accounts on the system are.." -ForegroundColor Yellow
foreach ($account in $accountfolders) {
    Write-Host $account.Name -ForegroundColor Magenta
} 

$question = Read-Host "Which account whould you'd like to have the App Data erased for?"

foreach ($account in $accountfolders) {
    if ($question -eq $account.Name) {
        try {
        Remove-Item -Path $join -Recurse -ErrorAction SilentlyContinue 
        Write-Host "Temp contents deleted from $($account.Name)" -ForegroundColor Green
        }
        catch {
            Write-Error $_
        }
    }
}