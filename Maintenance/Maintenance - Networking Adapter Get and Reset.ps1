<#
=============================================================================================
Name:           Networking - Get and Reset
Description:    This script will get a predefined list of Network Adapter properties and as if you want to flush the DNS cache and retrieve a new IP address.
Filepath:       \\usbot-unity9169-p1\Bot_Common\IT\PS Scripts
Prerequisites:  N/A

Script Tasks: 
~~~~~~~~~~~~~~~~~
1. Retrives the network adapter and specifies which one is current "Up"
2. Prompts for DNS cache flush
3. Prompts for IP renew.
4. Writes what was completed at the end.
============================================================================================
#>

# Flags to track if operations are completed
$dnsFlushed = $false
$ipRenewed = $false

$adapters = Get-NetAdapter | Select-Object Name, Status, InterfaceDescription, MacAddress
$adapters | Format-Table -AutoSize
$upAdapter = $adapters | Where-Object { $_.Status -eq 'Up' }
if ($upAdapter) {
    Write-Host "Adapter with status 'Up' found: $($upAdapter.Name)" -ForegroundColor Yellow
    Get-NetIPConfiguration -InterfaceAlias $upAdapter.Name
} else {
    Write-Output "No adapter with status 'Up' found."
}

$question = Read-Host "Would you like to flush the DNS cache? 'y/n'"
if ($question -match '^(Yes|y)$') {
    Clear-DnsClientCache
    if ($?) {
        Write-Host "DNS Cache cleared" -ForegroundColor Yellow
        $dnsflushed = $true
    } else {
        Write-Error "DNS cache was not cleared"
    }
} else {
    Write-Host "Operation canceled. Moving to next question." -ForegroundColor Red
}

$IP = Read-Host -Prompt "Do you want to release and renew the IP?"
if ($IP -match '^(Yes|y)$') {
    Invoke-Command -ScriptBlock {
        ipconfig.exe /release
        Start-Sleep -Seconds 3
        ipconfig.exe /renew
    }
    if ($?) {
        Write-Host "IP released and renewed." -ForegroundColor Yellow
        $ipRenewed = $true
    } else {
        Write-Error "IP release/renew operation failed."
    }
} else {
    Write-Host "You chose '$IP'. No action taken." -ForegroundColor Yellow
}

# Final confirmation if both operations were done
if ($dnsFlushed -and $ipRenewed) {
    Write-Host "Both DNS cache flush and IP renew operations are complete." -ForegroundColor Green
} elseif ($dnsFlushed) {
    Write-Host "DNS cache was flushed, but IP was not renewed." -ForegroundColor Green
} elseif ($ipRenewed) {
    Write-Host "IP was renewed, but DNS cache was not flushed." -ForegroundColor Green
} else {
    Write-Host "Neither DNS cache flush nor IP renew operations were performed." -ForegroundColor Red
}

Write-Host "Script is finished." -ForegroundColor Yellow