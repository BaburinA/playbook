   @echo off
   :: Запуск PowerShell скрипта из той же папки, где лежит bat-файл
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0INstall_MAX_new_ver.ps1"
   :: Передача кода возврата из PowerShell обратно в KSC
   exit /b %errorlevel%

