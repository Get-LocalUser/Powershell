function Get-RAM {
    $ram = Get-Process * | Sort-Object -Property PM, Description -Descending |
    Select-Object -Property @{Name='RAM Usage';Expression={($_.PM / 1MB)}}, Description, Name -First 5
    Write-Output "Top 3 Processes by RAM Usage (in MB):
    Name and shame!"
    Write-Output $ram
}

function Get-CPU {
    $cpu = Get-Process * | Sort-Object -Property CPU, Description -Descending | 
    Select-Object -Property @{Name='CPU Time';Expression={($_.CPU)}}, Description, Name -First 5
    Write-Output "Top 3 Processes by CPU Time: 
    Name and shame!"
    Write-Output $cpu
}

function Get-AllStats {
    Get-RAM | Format-Table -AutoSize
    Get-CPU | Format-Table -AutoSize
}

Get-AllStats

$ask = Read-Host "Would you like to end any of the processes listed?"
if ($ask -match '^(Yes|y)$') {
    $ask2 = Read-Host "Enter the 'Name' of the task you would like to end"
    if (-not [string]::IsNullOrEmpty($ask2)) {
        Stop-Process -Name $ask2 -ErrorAction SilentlyContinue
        if ($?) {
            Write-Host "Process '$ask2' has been terminated by the T-800 (Model 101) successfully." -ForegroundColor Green
        } else {
            Write-Host "Failed to kill the task." -ForegroundColor Red
        }
    } else {
        Write-Host "No name provided. Exiting doofus" -ForegroundColor Yellow
    }
} else {
    Write-Host "No tasks selected. Exiting." -ForegroundColor Yellow
}