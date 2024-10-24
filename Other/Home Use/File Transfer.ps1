$Source = "C:\Users\harison\Downloads\To Move"
$Destination = "\\server01\F Drive\Movies"
robocopy $Source $Destination /COPY:DAT /R:5 /W:5 /MT:32 /E