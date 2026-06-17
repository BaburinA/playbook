Get-AppxPackage -AllUsers | Where-Object {$_.Name -like "*WindowsCalculator*"} | ForEach-Object {
    Add-AppxPackage -Register "$($_.InstallLocation)\AppxManifest.xml" -DisableDevelopmentMode
}