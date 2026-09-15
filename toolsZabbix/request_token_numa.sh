#!/bin/bash
# Установка xo-cli - раскоментить
# npm install --global xo-cli
# Получение токена для заббикса под шаблон Numa
# Во вкладке “Macros” добавьте следующие макросы:
# {$NC.AUTH.TOKEN} - токен аутентификации (процедура получения токена описана здесь);
# {$NC.URL} - URL или IP-адрес Numa Collider;
# {$NC.PROXY.URL} - URL Proxy-сервера (опционально);
# {$NC.SR.THRESHOLD.CRIT} - критическое значение утилизации хранилища, в процентах (опционально);
# {$NC.SR.THRESHOLD.WARN} - высокое значение утилизации хранилища, в процентах (опционально).

/usr/local/bin/xo-cli create-token --au --expiresIn '180 days' https://192.168.0.76:443 admin admin
