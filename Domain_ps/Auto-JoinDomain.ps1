<#
.SYNOPSIS
    Автоматический скрипт ввода АРМ в домен Active Directory без интерактивных запросов.
.DESCRIPTION
    Предназначен для массового развертывания через SCCM, Intune, PDQ Deploy и т.д.
    Требует наличия файлов domain.key и domain.cred.
.PARAMETER DomainName
    Имя домена (например, contoso.local)
.PARAMETER NewComputerName
    Новое имя компьютера. Если не указано, останется текущее.
.PARAMETER KeyPath
    Путь к файлу ключа шифрования (domain.key)
.PARAMETER CredPath
    Путь к файлу зашифрованного пароля (domain.cred)
.PARAMETER LogPath
    Путь к файлу журнала (по умолчанию C:\Windows\Temp\JoinDomain.log)
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$DomainName,

    [Parameter(Mandatory=$false)]
    [string]$NewComputerName = $env:COMPUTERNAME,

    [Parameter(Mandatory=$true)]
    [string]$KeyPath,

    [Parameter(Mandatory=$true)]
    [string]$CredPath,

    [Parameter(Mandatory=$false)]
    [string]$LogPath = "C:\Windows\Temp\JoinDomain.log"
)

# --- Функция логирования ---
function Write-Log {
    param ([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LogPath -Value $logEntry
    if ($Level -eq "ERROR") { Write-Host $logEntry -ForegroundColor Red }
    else { Write-Host $logEntry -ForegroundColor Cyan }
}

# --- 1. Проверка прав администратора ---
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Log "ОШИБКА: Скрипт запущен без прав администратора." "ERROR"
    exit 1
}

Write-Log "========================================================="
Write-Log "Начало автоматического процесса ввода в домен: $DomainName"
Write-Log "Целевое имя компьютера: $NewComputerName"

# --- 2. Проверка текущего состояния ---
$CurrentDomain = (Get-WmiObject Win32_ComputerSystem).Domain
if ($CurrentDomain -eq $DomainName) {
    Write-Log "ИНФО: Компьютер уже находится в домене $DomainName. Действий не требуется." "INFO"
    exit 0 # Успешный код возврата для систем развертывания
}

# --- 3. Проверка доступности файлов учетных данных ---
if (-not (Test-Path $KeyPath) -or -not (Test-Path $CredPath)) {
    Write-Log "ОШИБКА: Не найдены файлы ключа ($KeyPath) или учетных данных ($CredPath)." "ERROR"
    exit 1
}

# --- 4. Сборка учетных данных ---
try {
    $Key = Get-Content $KeyPath
    $SecurePassword = Get-Content $CredPath | ConvertTo-SecureString -Key $Key
    # Извлекаем имя пользователя из файла cred (хак для восстановления PSCredential из SecureString)
    # Более надежный способ: хранить имя пользователя в скрипте или отдельном файле. 
    # Для простоты здесь мы предполагаем, что вы знаете имя пользователя, или оно зашито.
    # ДОБАВЬТЕ параметр $DomainUser в param() выше для полной гибкости!
    $DomainUser = "DOMAIN\AdminUser" # <-- ЗАМЕНИТЕ НА ВАШЕ ДОМЕННОЕ ИМЯ ПОЛЬЗОВАТЕЛЯ
    
    $Credentials = New-Object System.Management.Automation.PSCredential ($DomainUser, $SecurePassword)
    Write-Log "Учетные данные успешно расшифрованы." "INFO"
} catch {
    Write-Log "ОШИБКА расшифровки учетных данных: $($_.Exception.Message)" "ERROR"
    exit 1
}

# --- 5. Проверка связи с доменом ---
if (-not (Test-Connection -ComputerName $DomainName -Count 2 -Quiet)) {
    Write-Log "ОШИБКА: Контроллер домена $DomainName недоступен по сети. Проверьте DNS." "ERROR"
    exit 1
}

# --- 6. Ввод в домен ---
try {
    Write-Log "Выполняется команда Add-Computer..." "INFO"
    
    Add-Computer -DomainName $DomainName `
                 -NewName $NewComputerName `
                 -Credential $Credentials `
                 -Force `
                 -Restart `
                 -ErrorAction Stop

    Write-Log "УСПЕХ: Компьютер введен в домен и отправлен на перезагрузку." "INFO"
    # Скрипт завершится здесь, так как система перезагрузится.
    
} catch {
    Write-Log "ОШИБКА при вводе в домен: $($_.Exception.Message)" "ERROR"
    
    # Дополнительная диагностика для частых ошибок
    if ($_.Exception.Message -match "access is denied") {
        Write-Log "Подсказка: Неверный логин/пароль или у учетной записи нет прав на добавление ПК." "ERROR"
    } elseif ($_.Exception.Message -match "cannot find") {
        Write-Log "Подсказка: Неверное имя домена или проблемы с DNS." "ERROR"
    }
    
    exit 1 # Возвращаем код ошибки для системы развертывания
}