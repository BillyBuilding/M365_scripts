#Detection script

# Variables
$SSIDName = "MonEntreprise-WiFi"

# Vérifie si le profil existe déjà sur le poste
$ProfileExists = (netsh wlan show profiles) -match $SSIDName

# Vérifie si on est actuellement connecté à ce SSID
$Connected = (netsh wlan show interfaces) -match "SSID\s+:\s$SSIDName"

# Logique : Si le profil existe MAIS qu'on n'est pas connecté, il y a peut-être un souci
if ($ProfileExists -and -not $Connected) {
    Write-Output "Le profil existe mais n'est pas connecté. Tentative de remédiation."
    Exit 1 # Déclenche la remédiation
}
else {
    Write-Output "Tout est OK ou le réseau n'est pas à portée."
    Exit 0 # Pas d'action
}

#REMEDIATION SCRIPT

$SSIDName = "MonEntreprise-WiFi"

try {
    # On supprime le profil potentiellement corrompu
    netsh wlan delete profile name="$SSIDName"
    
    # On reset l'interface pour être sûr (équivalent d'un ON/OFF du bouton Wi-Fi)
    $WlanInterface = Get-NetAdapter | Where-Object { $_.Name -like "*Wi-Fi*" }
    Restart-NetAdapter -Name $WlanInterface.Name -ErrorAction SilentlyContinue
    
    Write-Output "Profil supprimé et carte redémarrée. La reconnexion automatique va se lancer."
}
catch {
    Write-Error "Erreur lors du reset Wi-Fi."
}
