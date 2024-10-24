$HTML = Invoke-RestMethod 'https://bofhcalendar.com/'
$null = $HTML -match '<span id="date_excuse" style="font-style: italic">(?<excuse>.*)<\/span>'
Write-Host "Today's excuse: " -ForegroundColor Yellow -NoNewline
Write-Host $Matches['excuse'] -ForegroundColor Blue