Import-Module ActiveDirectory

# variables
$Credential = (Get-Credential)
$server = "SRVDC01.AKSOR.HD"



# Define the OU path and the group name
$OU = "OU=Users,OU=USA,DC=AKSOR,DC=HD"
$GroupName = "SDP-USA"

# Get all users from the specified OU
$Users = Get-ADUser -Server $server -Credential $credential -SearchBase $OU -Filter *

# Add each user to the specified group
foreach ($User in $Users) {
    Add-ADGroupMember -Server $server -Credential $credential -Identity $GroupName -Members $User.SamAccountName
}

Write-Host "All users from $OU have been added to the group $GroupName."
