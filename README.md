# M365_scripts
This repo is a collection of ready to use entra scripts that are useful on a daily basis as a Administrator

## HOW TO USE 

You can launch the scripts from Powershell ISE or any IDE with a powershell terminal. 
Once launch you will need to log in with your admin credentials.
Resulsts are often displayed as json.

### Wi-Fi Connectivity & Profile Reset

This package ensures devices maintain connectivity to the corporate network by identifying and fixing "stuck" Wi-Fi profiles.

*   **Detection Script**: Checks if the target SSID profile (`MonEntreprise-WiFi`) is present on the device. If the profile exists but the device is **not** currently connected to that specific network, it returns `Exit 1` to trigger the remediation.
*   **Remediation Script**: Resolves the issue by deleting the saved Wi-Fi profile and forcibly restarting the Wi-Fi network adapter. This forces the OS to renegotiate a clean connection handshake.
