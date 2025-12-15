#This script 

Import-Module ActiveDirectory

# variables
$Credential = (Get-Credential)
$server = ""



# Define the OU path and the group name
$OU = "OU=,OU=,DC=,DC="
$GroupName = ""

# Get all users from the specified OU
$Users = Get-ADUser -Server $server -Credential $credential -SearchBase $OU -Filter *

# Add each user to the specified group
foreach ($User in $Users) {
    Add-ADGroupMember -Server $server -Credential $credential -Identity $GroupName -Members $User.SamAccountName
}

Write-Host "All users from $OU have been added to the group $GroupName."
