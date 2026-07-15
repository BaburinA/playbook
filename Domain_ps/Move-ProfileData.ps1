# ==============================================================================
# Скрипт переноса пользовательских данных из старого профиля в новый
# Требует прав Администратора
# ==============================================================================

param (
    [Parameter(Mandatory=$true)]
    [string]$OldUser,
    
    [Parameter(Mandatory=$true)]
    [string]$NewUser
)

# Проверка прав администратора
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ОШИБКА: Запустите скрипт от имени Администратора!" -ForegroundColor Red
    exit 1
}

$OldPath = "C:\Users\$OldUser"
$NewPath = "C:\Users\$NewUser"

# Проверка существования папок
if (-not (Test-Path $OldPath)) {
    Write-Host "ОШИБКА: Папка старого пользователя не найдена: $OldPath" -ForegroundColor Red
    exit 1
}

# Важно: Новый пользователь должен хотя бы один раз войти в систему, чтобы создался профиль
if (-not (Test-Path $NewPath)) {
    Write-Host "ОШИБКА: Папка нового пользователя не найдена: $NewPath" -ForegroundColor Yellow
    Write-Host "Попросите пользователя $NewUser войти в систему один раз, чтобы Windows создала профиль, затем запустите скрипт снова." -ForegroundColor Yellow
    exit 1
}

# Папки, которые нужно перенести (безопасный список)
$FoldersToCopy = @(
    "Desktop", "Documents", "Downloads", "Pictures", "Videos", 
    "Music", "Favorites", "Contacts", "Links"
)

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "Начинается перенос данных:" -ForegroundColor Cyan
Write-Host "Из: $OldPath"
Write-Host "В:  $NewPath"
Write-Host "========================================================" -ForegroundColor Cyan

foreach ($Folder in $FoldersToCopy) {
    $Source = Join-Path $OldPath $Folder
    $Destination = Join-Path $NewPath $Folder

    if (Test-Path $Source) {
        Write-Host "Копирование: $Folder..." -ForegroundColor Yellow
        
        # Используем Robocopy для надежного копирования (сохраняет права, пропускает ошибки)
        # /E - копирует подпапки, /Z - возобновляемый режим, /R:2 /W:5 - минимум повторов при ошибках
        $RobocopyArgs = @($Source, $Destination, "/E", "/Z", "/R:2", "/W:5", "/NP", "/NFL", "/NDL", "/NJH", "/NJS")
        $Process = Start-Process -FilePath "robocopy.exe" -ArgumentList $RobocopyArgs -NoNewWindow -Wait -PassThru
        
        # Robocopy возвращает коды 0-7 как успех, >7 как ошибку
        if ($Process.ExitCode -le 7) {
            Write-Host "Успешно: $Folder" -ForegroundColor Green
        } else {
            Write-Host "Ошибка при копировании $Folder (Код: $($Process.ExitCode))" -ForegroundColor Red
        }
    } else {
        Write-Host "Пропуск: $Folder (не существует в старом профиле)" -ForegroundColor DarkGray
    }
}

Write-Host "========================================================" -ForegroundColor Green
Write-Host "Перенос пользовательских файлов завершен!" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green

# Как использовать:
# Сохраните как Move-ProfileData.ps1 и запустите от админа:
# .\Move-ProfileData.ps1 -OldUser "Ivanov" -NewUser "Petrov"

