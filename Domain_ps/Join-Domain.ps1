# ==============================================================================
# Скрипт для ввода АРМ (рабочей станции) в домен Active Directory
# Требует запуска от имени Администратора
# ==============================================================================

# 1. Проверка прав администратора
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ОШИБКА: Скрипт должен быть запущен от имени Администратора!" -ForegroundColor Red
    Write-Host "Щелкните правой кнопкой мыши на PowerShell и выберите 'Запуск от имени администратора'." -ForegroundColor Yellow
    pause
    exit
}

# 2. Вывод текущей информации (Output)
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "  Текущая информация о системе" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "Текущее имя компьютера : $env:COMPUTERNAME"
Write-Host "Текущий домен/рабочая группа : $(Get-WmiObject Win32_ComputerSystem).Domain"
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""

# 3. Ввод данных пользователем (Input)
$targetDomain = Read-Host "Введите имя домена для ввода (например, contoso.local)"

$newComputerName = Read-Host "Введите НОВОЕ имя компьютера (оставьте пустым, чтобы не менять)"
if ([string]::IsNullOrWhiteSpace($newComputerName)) {
    $newComputerName = $env:COMPUTERNAME
}

Write-Host ""
Write-Host "Для ввода в домен требуются учетные данные пользователя с правами добавления компьютеров в домен." -ForegroundColor Yellow
$domainCreds = Get-Credential -Message "Введите логин и пароль доменного администратора"

if ($null -eq $domainCreds) {
    Write-Host "Операция отменена: учетные данные не введены." -ForegroundColor Red
    pause
    exit
}

# 4. Процесс ввода в домен
Write-Host ""
Write-Host "Начинается процесс ввода в домен '$targetDomain'..." -ForegroundColor Cyan
Write-Host "Новое имя компьютера будет: '$newComputerName'" -ForegroundColor Cyan
Write-Host "Пожалуйста, подождите..." -ForegroundColor Yellow

try {
    # Проверка доступности контроллера домена (простой пинг)
    if (-not (Test-Connection -ComputerName $targetDomain -Count 2 -Quiet)) {
        Write-Host "ПРЕДУПРЕЖДЕНИЕ: Не удается пропинговать домен '$targetDomain'. Проверьте настройки DNS и сетевое подключение." -ForegroundColor Red
        $continue = Read-Host "Продолжить попытку ввода в домен? (y/n)"
        if ($continue -ne 'y') { exit }
    }

    # Команда добавления в домен. Параметр -Restart автоматически перезагрузит ПК после успешного выполнения
    Add-Computer -DomainName $targetDomain `
                 -NewName $newComputerName `
                 -Credential $domainCreds `
                 -Force `
                 -Restart `
                 -ErrorAction Stop

    Write-Host "========================================================" -ForegroundColor Green
    Write-Host "  УСПЕХ!" -ForegroundColor Green
    Write-Host "  Компьютер успешно переименован и введен в домен." -ForegroundColor Green
    Write-Host "  Система будет перезагружена через 10 секунд." -ForegroundColor Green
    Write-Host "========================================================" -ForegroundColor Green
    
    Start-Sleep -Seconds 10

} catch {
    Write-Host "========================================================" -ForegroundColor Red
    Write-Host "  ОШИБКА при вводе в домен!" -ForegroundColor Red
    Write-Host "  Сообщение: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "========================================================" -ForegroundColor Red
    Write-Host "Проверьте:"
    Write-Host "1. Правильность имени домена."
    Write-Host "2. Что DNS-сервером на этом АРМ указан контроллер домена."
    Write-Host "3. Правильность логина/пароля и наличие прав у учетной записи."
    pause
}