$mp3files = Get-ChildItem -Path "C:\Users\Harison\Downloads\Spotify Music" -Filter "*.mp3"
$artistfolder = "C:\Users\Harison\Downloads\Spotify Music\Artists"

foreach ($mp3file in $mp3files) 
{
    $albumtitle = (Get-ID3Tag -path $mp3file.FullName).album
    $artist = (get-ID3Tag -Path $mp3file.FullName).FirstAlbumArtist

    # Create the artist folder if it doesn't already exist
    if (-not (Test-Path "$artistfolder\$artist")) 
    {
        New-Item -Path "$artistfolder\$artist" -ItemType Directory
    }

    # Create the album folder within the artist folder if it doesn't already exist
    if (-not (Test-Path "$artistfolder\$artist\$albumtitle")) 
    {
        New-Item -Path "$artistfolder\$artist\$albumtitle" -ItemType Directory
    }

    # Move the MP3 file to the album folder
    move-item -path ($mp3file.FullName) -destination "$artistfolder\$artist\$albumtitle"
}
foreach ($mp3file in Get-ChildItem $artistfolder\$artist\$albumtitle)
{
    Get-ChildItem $mp3file | Rename-Item -NewName { $_.Name.Substring($_.Name.IndexOf("-") + 1)}
}
