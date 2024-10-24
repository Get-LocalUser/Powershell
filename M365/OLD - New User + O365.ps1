<#
    .NOTES
    =============================================================
    *This will only work for Coldstream users right now*
    You will to add the users phone number in SharePoint manually.
    The Zoom phone number will need to be added manually later.
    =============================================================
    .DESCRIPTION
    Creates new AD user account from a few initial prompts.
    Adds user to mirrored users groups.
    Assigns and sets all M365 settings and licenses.
    ======================================================
#>



# Creates a record of all parts of the PowerShell session to a text file.
$transcriptpath = "C:\powershelltranscripts\M365NewUser.txt"

if (Test-Path $transcriptpath) {
    $counter = 1
    do {
        $newPath = "$transcriptpath.$counter"
        $counter++
    } while (Test-Path $newPath)

    Start-Transcript -Path $newPath
} else {
    Start-Transcript -Path $transcriptpath
}

# Import required modules..Will only work for Coldstream accounts for now.
Import-Module ActiveDirectory

# Define variables
$Username = Read-Host "Enter employees preferred/alternate first and last name as 'John Doe' without quotations and no dots."
$Domain = Read-Host "Enter the users domain name such as 'Coldstream.com, 'CPAHSA.com'"
$Manager = Read-Host "Enter the mangagers name 'John.Doe'"
$Department = Read-Host "Enter the users department"
$Description = Read-Host "Enter the users title"
$Cellphone = Read-Host "Enter the users cell phone number with dashes Eg. '253-xxx-xxxx'"
$Office = Read-Host "Please enter the office location"
$Company = Read-Host "Enter the company name such as 'Coldstream', 'FIT Insurnace' etc"
$OU = @{
    "Bellevue" = ""
    "Kenai" = ""
    "Kirkland HSA" = ""
    "Mercer Island" = ""
    "Portland" = ""
    "Seattle" = ""
} 

$selectedKey = Read-Host "Please enter one of the following OU's to place the user in: $($OU.Keys -join ', ')"
$Path = $OU[$selectedKey]

# Locations/Addresses
$AddressDetails = @{
    Bellevue = @{
        StreetAddress = "7773 stbduhdwuid"
        City = "Cityy"
        State = "Thisstate"
        PostalCode = "900001"
        Country = "US"
        Fax = "555-555-5555"
    }

    Kenai = @{
        StreetAddress = "7773 stbduhdwuid"
        City = "Cityy"
        State = "Thisstate"
        PostalCode = "900001"
        Country = "US"
        Fax = "555-555-5555"
    }

    Kirkland = @{
        StreetAddress = "7773 stbduhdwuid"
        City = "Cityy"
        State = "Thisstate"
        PostalCode = "900001"
        Country = "US"
        Fax = "555-555-5555"
    }

    "Mercer Island" = @{
        StreetAddress = "7773 stbduhdwuid"
        City = "Cityy"
        State = "Thisstate"
        PostalCode = "900001"
        Country = "US"
        Fax = "555-555-5555"
    }

    Portland = @{
        StreetAddress = "7773 stbduhdwuid"
        City = "Cityy"
        State = "Thisstate"
        PostalCode = "900001"
        Country = "US"
        Fax = "555-555-5555"
    }


    Seattle = @{
        StreetAddress = "7773 stbduhdwuid"
        City = "Cityy"
        State = "Thisstate"
        PostalCode = "900001"
        Country = "US"
        Fax = "555-555-5555"
    }
}

# Details about the user
$UserDetails = @{
    GivenName = $Username -replace '\s+\S+$'
    Surname = $Username -replace '^\S+\s'
    DisplayName = $Username
    UserPrincipalName = ($Username -replace ' ', '') + "@" + $Domain
    SamAccountName = $Username -replace ' ', '.'
    Path = $Path
    Description = $Description
    Title = $Description
    Office = $Office
    Email = ($Username -replace ' ', '.') + "@" + $Domain ### I changed this last time to include the period. 
    HomePage = "www.coldstream.com"
    MobilePhone = $Cellphone
    Department = $Department
    Manager = $Manager
    Company = $Company
    StreetAddress = $AddressDetails[$Office].StreetAddress
    City = $AddressDetails[$Office].City
    State = $AddressDetails[$Office].State
    PostalCode = $AddressDetails[$Office].PostalCode
    Country = $AddressDetails[$Office].Country
    Fax = $AddressDetails[$Office].Fax
}

# Create AD User with the provided properties
Write-Host "The next prompt will ask you for an account, enter the users account like this 'John.Doe'" -ForegroundColor Yellow
try {
    New-ADUser @UserDetails -AccountPassword (Read-Host -AsSecureString "Please enter the password for the users account") -Enabled $true 
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
}

# Set the users mailNickname attribute
$mailNickname = $Username -replace ' ', '.'
Get-ADUser -Identity $mailNickname -Properties * | Set-ADUser -Replace @{mailNickname=$mailNickname}

# Copy Group memberships from mirrored user.
$copy = Read-host "Enter username to copy from:"
$paste  = Read-host "Enter username to copy to:"

try {
    Get-ADUser -Identity $copy -Properties memberof | Select-Object -ExpandProperty memberof | Add-ADGroupMember -Members $paste
    if ($copy -eq $null) { break } # Added this line here. if error, remove
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
}

Write-Host "On Prem AD config done..proceeding to M365 steps" -ForegroundColor Green
Start-Sleep -Seconds 5



<#
    .NOTES
        -------------This is the beginning of the M365 portion-------------
#>



# Import modules and if error, install modules.
try {
    Import-Module -Name Microsoft.Graph.Users, Microsoft.Graph.Users.Actions -ErrorAction Stop
    Import-Module -Name ExchangeOnlineManagement -ErrorAction Stop
    # Import-Module -Name Microsoft.Online.SharePoint.PowerShell -ErrorAction Stop
    Write-Host "Modules imported successfully." -Foregroundcolor Green
} catch {
    Write-Host "Error occurred: $_" -Foregroundcolor Red
    Write-Host "Installing ExchangeOnlineManagement and Microsoft.Graph...this will take a few minutes" -Foregroundcolor Yellow
    $moduleinstall = Install-Module -Name ExchangeOnlineManagement -Scope AllUsers -AllowClobber -ErrorAction Stop; Install-Module -Name Microsoft.Graph -Scope AllUsers -AllowClobber -ErrorAction Stop # Add sharepoint module here if desired
}

# Check if module was installed successfully and then import it
if ($moduleinstall) {
    Import-Module -Name ExchangeOnlineManagement, Microsoft.Graph.Users, Microsoft.Graph.Users.Actions
}

# Connect to MgGraph & Exchange.
$UserAdmin = Read-Host "Enter your admin email account"
Connect-MgGraph -Scope "User.ReadWrite.All","Group.ReadWrite.All","Organization.Read.All"
Connect-ExchangeOnline -UserPrincipalName $UserAdmin -ShowBanner:$False
Start-Sleep -Seconds 5 

# Check if the user is synced up into M365
$UserID = ($Username -replace ' ', '') + "@" + $Domain
while($true) {
    if(Get-MgUser -UserID $UserID) {
        Write-Output "User found, proceeding..."
        break
    } else {
        Write-Output "User not found, sleeping for 15 minutes..."
        Start-Sleep -Seconds 900
    }
}

# Assign the E3 and E5 licenses to the user
$E5Sku = Get-MgSubscribedSku -All | Where SkuPartNumber -eq 'SPE_E5'
$E3Sku = Get-MgSubscribedSku -All | Where SkuPartNumber -eq 'SPE_E3'
$ThreatProtectSku = Get-MgSubscribedSku -All | Where SkuPartNumber -eq 'IDENTITY_THREAT_PROTECTION'
$addLicenses = @(
  @{SkuId = $E5Sku.SkuId},
  @{SkuId = $E3Sku.SkuId},
  @{SkuId = $ThreatProtectSku.SkuId}
  )

try {
    Set-MgUserLicense -UserId $UserID -AddLicenses $addLicenses -RemoveLicenses @()
    Write-Host "Licenses assigned successfully" -ForegroundColor Green 
} catch {
    Write-Host "Failed to assign license: $_" -ForegroundColor Red
}

# Define the maximum number of attempts and search for users mailbox. If no mailbox is found, wait 5 minutes and try again with 3 attempts.
$maxAttempts = 3
$Attempt = 0
while ($Attempt -lt $MaxAttempts) {
    $mailboxresults = Get-EXOMailbox -Identity $UserID -ErrorAction SilentlyContinue
    if ($null -eq $mailboxresults) {
        Write-Output "Mailbox not yet created..waiting 5 minutes and then will try again automatically"
        Start-Sleep -Seconds 300
        $Attempt++
    } else {
    Write-Output "Mailbox found..proceeding to next steps"
    break
    }
}

# Check if the maximum number of attempts was reached
if ($attempt -eq $maxAttempts) {
    Write-Host "Maximum attempts reached. Mailbox not found. Please run the rest of this script later when you have verified the mailbox exists." -ForegroundColor Red
    Exit 1
}

# Change the retention policy to "Archive +1 Year 3 Months"
try {
    Set-Mailbox -Identity $UserID -RetentionPolicy "Archive +1 Year 3 Months" -ErrorAction Stop
    Write-Host "Retention policy set. Moving on.." -ForegroundColor Green
} catch {
    Write-Host "Failed to set retention policy: $_" -ForegroundColor Red
}

# Add user to the Anti-Phishing policy
$logonname = Read-Host "Enter users logon name such as 'Ben.Hogan'"
try {
    Set-AntiPhishPolicy -Identity "Coldstream Anti-phishing policy" -TargetedUsersToProtect @{Add="$logonname;$UserID"} -ErrorAction Stop
    Write-Host "User added to the Anti-Phishing Policy" -ForegroundColor Green
} catch {
    Write-Host "Failed to set anti-phishing policy: $_" -ForegroundColor Red
}

# Define variables for the security groups and set calendar permissions
# Exit the pop-up window if no security group is required
$SecGrp = @{
    "SecGrp_ConferenceRooms" = "Conference Rooms"
    "SecGrp_CPAHSA" = "CPAHSA"
    "SecGrp_FIT" = "FIT"
    "SecGrp_IT" = "IT"
    "SecGrp_RGC" = "RGC"
    "SecGrp_TeamCervantes" = "Team Cervantes"
    "SecGrp_TeamFitzwilson" = "Team Fitzwilson"
    "SecGrp_TeamMcCracken" = "Team McCracken"
    "SecGrp_TeamParacle" = "Team Paracle"
    "SecGrp_TeamReynolds" = "Team Reynolds"
    "SecGrp_TeamRosenbaum" = "Team Rosenbaum"
    "SecGrp_TeamSeidman" = "Team Seidman"
    "SecGrp_TeamShemeta" = "Team Shemeta"
 }

# Using Out-GridView
$SelectedKey = Read-Host "Please select the appropriate security group for the user $($SecGrp.Keys -join ', ')"
$SelectedGroup = $SecGrp[$SelectedKey]
 
# Add mailbox permissions
Set-MailboxFolderPermission -Identity "$($UserID):\calendar" -User default -AccessRights Reviewer
 
Add-MailboxFolderPermission -Identity "$($UserID):\calendar" -User SecGrp_IT -AccessRights Owner
 
Add-MailboxFolderPermission -Identity "$($UserID):\calendar" -User $SelectedGroup -AccessRights PublishingEditor
 
# Display and verify mailbox permissions
Get-MailboxFolderPermission -Identity "$email`:\calendar"
Start-Sleep -Seconds 5

# Disable old Email Authentication protols
try {
    Set-CasMailbox -Identity $UserID  -PopEnabled $false -ImapEnabled $false -ActiveSyncEnabled $False -SmtpClientAuthenticationDisabled $True
    Write-Host "Auth protocols set for the user" -ForegroundColor Green
} catch {
    Write-Host "Failed to set auth protocols: $_" -ForegroundColor Red
}

# Disconnect from the PS module sessions
Disconnect-ExchangeOnline -Confirm
Disconnect-Graph

Stop-Transcript

Write-Host "Script is finished. Press any key to exit." -ForegroundColor Green

# Read the next key pressed without waiting for Enter
[System.Console]::ReadKey() | Out-Null

Exit
