# ==============================================================================
# Helper script: Генерация зашифрованных учетных данных для массового ввода в домен
# ==============================================================================

$Password = "ВашСуперСекретныйПарольАдмина" # Замените на реальный пароль
$Username = "DOMAIN\AdminUser"                # Замените на реальный логин
$Path = "C:\Temp\DomainCreds"                 # Путь для сохранения файлов

# Создаем папку, если её нет
if (-not (Test-Path $Path)) { New-Item -ItemType Directory -Path $Path -Force | Out-Null }

# 1. Генерируем случайный 256-битный ключ AES
$Key = New-Object Byte[] 32
[Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($Key)
$Key | Out-File "$Path\domain.key"

# 2. Шифруем пароль с помощью этого ключа
$SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
$SecurePassword | ConvertFrom-SecureString -Key $Key | Out-File "$Path\domain.cred"

Write-Host "Файлы успешно созданы в $Path" -ForegroundColor Green
Write-Host "Перенесите оба файла (domain.key и domain.cred) на целевые АРМ или в общую сетевую папку." -ForegroundColor Yellow