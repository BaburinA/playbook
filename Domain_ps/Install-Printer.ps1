# Check for Admin rights
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Admin rights required. Restarting..." -ForegroundColor Yellow
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

$Host.UI.RawUI.WindowTitle = "Network Printer Installation"
Clear-Host

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "       NETWORK PRINTER INSTALLATION     " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Select a printer to install:"
Write-Host "1. Accounting Printer (IP: 192.168.1.10)"
Write-Host "2. Sales Dept Printer (IP: 192.168.1.20)"
Write-Host "3. Warehouse Printer (IP: 192.168.1.30)"
Write-Host "4. Exit"
Write-Host "========================================" -ForegroundColor Cyan

$choice = Read-Host "Enter option number (1-4)"

$portName = $null; $printerIP = $null; $driverName = $null; $printerName = $null

switch ($choice) {
    "1" {
        $portName = "IP_192.168.1.10"
        $printerIP = "192.168.1.10"
        $driverName = "HP Universal Printing PCL 6" 
        $printerName = "Accounting_HP_M428"
    }
    "2" {
        $portName = "IP_192.168.1.20"
        $printerIP = "192.168.1.20"
        $driverName = "Xerox Global Print Driver PCL6"
        $printerName = "Sales_Xerox_VersaLink"
    }
    "3" {
        $portName = "IP_192.168.1.30"
        $printerIP = "192.168.1.30"
        $driverName = "Kyocera Universal Print Driver PCL"
        $printerName = "Warehouse_Kyocera_ECOSYS"
    }
    "4" { Write-Host "Exiting."; exit }
    default { Write-Host "Invalid choice. Exiting." -ForegroundColor Red; Start-Sleep 2; exit }
}

Write-Host "`nInstalling printer: $printerName..." -ForegroundColor Green

if (-not (Get-PrinterPort -Name $portName -ErrorAction SilentlyContinue)) {
    Write-Host "Creating port $portName for IP $printerIP..." -ForegroundColor Yellow
    try { Add-PrinterPort -Name $portName -PrinterHostAddress $printerIP -ErrorAction Stop } 
    catch { Write-Host "Port creation error: $_" -ForegroundColor Red; Read-Host "Press Enter to exit"; exit }
} else { Write-Host "Port $portName already exists." -ForegroundColor DarkGray }

if (-not (Get-PrinterDriver -Name $driverName -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Driver '$driverName' not found!" -ForegroundColor Red
    Read-Host "Press Enter to exit"; exit
}

if (-not (Get-Printer -Name $printerName -ErrorAction SilentlyContinue)) {
    Write-Host "Adding printer..." -ForegroundColor Yellow
    try { 
        Add-Printer -Name $printerName -DriverName $driverName -PortName $portName -ErrorAction Stop
        Write-Host "Printer '$printerName' installed successfully!" -ForegroundColor Green
    } catch { Write-Host "Printer add error: $_" -ForegroundColor Red }
} else { Write-Host "Printer '$printerName' is already installed." -ForegroundColor DarkYellow }

Write-Host "`n========================================" -ForegroundColor Cyan
Read-Host "Press Enter to finish"