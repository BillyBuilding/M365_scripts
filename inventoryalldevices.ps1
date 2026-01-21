# output filename will be prefixed with this name.
$CsvBaseFileName = "Intune_Devices_Report"

# The properties to select from the Graph API call. 
$propertiesToSelect = @(
    "deviceName",
    "managementAgent",
    "complianceState",
    "userPrincipalName",
    "lastSyncDateTime",
    "manufacturer",
    "serialNumber",
    "userDisplayName",
    "azureADDeviceId"
)



# Check if the Microsoft.Graph module is installed
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Write-Host "Microsoft.Graph PowerShell module not found." -ForegroundColor Yellow
    $installChoice = Read-Host "Do you want to install it now? (Y/N)"
    if ($installChoice -eq 'Y') {
        Write-Host "Installing Microsoft.Graph module..." -ForegroundColor Green
        Install-Module Microsoft.Graph -Scope CurrentUser -Repository PSGallery -Force
    }
    else {
        Write-Host "Script cannot continue without the required module. Exiting." -ForegroundColor Red
        return
    }
}

# Define the required permissions (scopes) for the Graph API call
$requiredScopes = "DeviceManagementManagedDevices.Read.All"

Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
try {
    # Connect using interactive login. The token is cached for subsequent runs.
    Connect-MgGraph -Scopes $requiredScopes
    Write-Host "Successfully connected." -ForegroundColor Green
}
catch {
    Write-Host "Failed to connect to Microsoft Graph. Please check your credentials and permissions." -ForegroundColor Red
    Write-Error $_
    return
}


try {
    Write-Host "Fetching all managed devices from Intune. This may take a moment..." -ForegroundColor Cyan
    # -All parameter ensures we get all pages of results in a single command
    $allDevices = Get-MgDeviceManagementManagedDevice -All -Property $propertiesToSelect -ErrorAction Stop

    if (-not $allDevices) {
        Write-Host "No managed devices found." -ForegroundColor Yellow
        return
    }

    Write-Host "Processing $($allDevices.Count) devices..." -ForegroundColor Cyan

    $reportData = foreach ($device in $allDevices) {
        # --- Name Inversion Logic ---
        # "LastName, FirstName" from "FirstName LastName"
        $formattedName = $device.UserDisplayName
        if ($device.UserDisplayName -and $device.UserDisplayName.Contains(" ")) {
            # Split by the first space to handle middle names/initials gracefully
            $nameParts = $device.UserDisplayName.Split(' ', 2)
            if ($nameParts.Count -eq 2) {
                $formattedName = "$($nameParts[1]), $($nameParts[0])"
            }
        }

        # --- Date Formatting Logic ---
        # 'dd/MM/yyyy'
        $formattedDate = if ($device.LastSyncDateTime) {
            Get-Date -Date $device.LastSyncDateTime -Format 'dd/MM/yyyy'
        }
        else {
            "" # Return an empty string if the date is null
        }

        # Create a custom object with the desired column names and formatted data
        [PSCustomObject]@{
            'Device name'               = $device.DeviceName
            'Managed by'                = $device.ManagementAgent
            'Compliance'                = $device.ComplianceState
            'Primary user UPN'          = $device.UserPrincipalName
            'Last check-in'             = $formattedDate
            'Manufacturer'              = $device.Manufacturer
            'Serial number'             = $device.SerialNumber
            'Primary user display name' = $formattedName
            'Microsoft Entra Device ID' = $device.AzureADDeviceId
        }
    }

    #region --- CSV Export ---

    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $outputFile = Join-Path -Path $PSScriptRoot -ChildPath "$($CsvBaseFileName)_$($timestamp).csv"

    Write-Host "Exporting report to: $outputFile" -ForegroundColor Cyan
    $reportData | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8

    Write-Host "Report successfully generated!" -ForegroundColor Green

    #endregion --- CSV Export ---

}
catch {
    Write-Host "An error occurred during device processing or export." -ForegroundColor Red
    Write-Error $_
}
finally {
    # It's good practice to disconnect the session
    Write-Host "Disconnecting from Microsoft Graph." -ForegroundColor Cyan
    Disconnect-MgGraph
}
