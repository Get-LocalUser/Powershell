$folder = "C:\Users\harison\Downloads\To Move"

Get-ChildItem $folder | ForEach-Object {
    $newname = $_.Name -replace '\.', ' '  # Modify only the file name
    $newpath = Join-Path $_.DirectoryName $newname  # Create the new full path
    Rename-Item -Path $_.FullName -NewName $newpath
}