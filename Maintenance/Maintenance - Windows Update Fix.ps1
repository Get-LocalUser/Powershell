# havent tested this

if ((Get-Service -Name BITS).Status -eq "Running") {
    Restart-Service -Name BITS -Verbose
}

Start-Service -Name wuauserv -Verbose

# add to other script if up top doesnt resolve issue.
# Remove-Item -Recurse -Force C:\Windows\SoftwareDistribution\*