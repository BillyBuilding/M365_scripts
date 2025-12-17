#Detection Script
# Seuils
$FreeSpaceThreshold = 20 # En pourcentage
$DaysInactive = 60

# Vérif Espace Disque
$Disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'"
$FreeSpacePercent = ($Disk.FreeSpace / $Disk.Size) * 100

# Vérif s'il y a des profils inactifs (Exclut SYSTEM, NetworkService, etc.)
$OldProfiles = Get-CimInstance -ClassName Win32_UserProfile | 
               Where-Object { ($_.LastUseTime -lt (Get-Date).AddDays(-$DaysInactive)) -and ($_.Special -eq $false) }

if ($FreeSpacePercent -lt $FreeSpaceThreshold -and $OldProfiles) {
    Write-Output "Espace disque critique ($([math]::Round($FreeSpacePercent))%) et profils obsolètes détectés."
    Exit 1 # Déclenche la remédiation
}
else {
    Write-Output "Espace disque suffisant ou aucun vieux profil à purger."
    Exit 0 # Pas d'action
}


#Remediation Script
$DaysInactive = 60

try {
    # Récupération des profils à supprimer
    $OldProfiles = Get-CimInstance -ClassName Win32_UserProfile | 
                   Where-Object { ($_.LastUseTime -lt (Get-Date).AddDays(-$DaysInactive)) -and ($_.Special -eq $false) -and ($_.Loaded -eq $false) }

    foreach ($Profile in $OldProfiles) {
        # Suppression propre via la méthode WMI
        $Profile | Remove-CimInstance -ErrorAction Continue
        Write-Output "Profil supprimé : $($Profile.LocalPath)"
    }
}
catch {
    Write-Error "Erreur lors du nettoyage des profils."
}
