$ErrorActionPreference = "Stop"
$downloadUrl = "https://download.cdn.oneme.ru/win/release/MAX.msi"
$installerPath = "$env:TEMP\MAX.msi"
$metaFile = "$env:APPDATA\MAX_meta.json"

# --- ШАГ 1: Проверка заголовков ---
try {
    $response = Invoke-WebRequest -Uri $downloadUrl -Method Head -UseBasicParsing -TimeoutSec 30
    $lastModified = $response.Headers["Last-Modified"]
    $etag = $response.Headers["ETag"]
    $contentLength = $response.Headers["Content-Length"]
} catch {
    Write-Host "Ошибка при получении заголовков: $_"
    exit 1
}

# --- ШАГ 2: Сравнение с прошлым разом ---
$needDownload = $true
if (Test-Path $metaFile) {
    $old = Get-Content $metaFile -Raw | ConvertFrom-Json
    if ($old.LastModified -eq $lastModified -and $old.ETag -eq $etag -and $old.ContentLength -eq $contentLength) {
        Write-Host "Файл на CDN не изменился. Скачивание не требуется." -ForegroundColor Yellow
        $needDownload = $false
    }
}

# --- ШАГ 3: Скачивание ---
if ($needDownload) {
    Write-Host "Скачиваем новый файл..." -ForegroundColor Green
    Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath -UseBasicParsing
    @{ LastModified=$lastModified; ETag=$etag; ContentLength=$contentLength } | ConvertTo-Json | Set-Content $metaFile
}

# --- ШАГ 4: Чтение версии из MSI ---
function Get-MsiVersion {
    param([string]$Path)
    
    $installer = $null; $database = $null; $view = $null
    
    try {
        $installer = New-Object -ComObject WindowsInstaller.Installer
        $database = $installer.OpenDatabase($Path, 0)
        $view = $database.OpenView("SELECT Value FROM Property WHERE Property='ProductVersion'")
        $view.Execute()
        $record = $view.Fetch()
        if ($record) { return $record.StringData(1) }
        return "unknown"
    }
    catch { return "unknown" }
    finally {
        if ($view) { $view.Close() }
        if ($view) { [System.Runtime.Interopservices.Marshal]::ReleaseComObject($view) | Out-Null }
        if ($database) { [System.Runtime.Interopservices.Marshal]::ReleaseComObject($database) | Out-Null }
        if ($installer) { [System.Runtime.Interopservices.Marshal]::ReleaseComObject($installer) | Out-Null }
        [GC]::Collect()
        [GC]::WaitForPendingFinalizers()
    }
}

$msiVersion = Get-MsiVersion -Path $installerPath
Write-Host "Версия в файле: $msiVersion"

# --- ШАГ 5: Сравнение с установленной ---
$installed = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
                               "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue |
             Where-Object { $_.DisplayName -match 'MAX' } | Select-Object -First 1

$installedVersion = if ($installed) { $installed.DisplayVersion } else { "0.0.0" }
Write-Host "Установленная версия: $installedVersion"

if ([version]$installedVersion -ge [version]$msiVersion) {
    Write-Host "У вас актуальная версия. Установка не требуется." -ForegroundColor Green
} else {
    Write-Host "Устанавливаем новую версию $msiVersion..." -ForegroundColor Green
    # Start-Process msiexec.exe -ArgumentList "/i `"$installerPath`" /qn /norestart" -Wait
}
