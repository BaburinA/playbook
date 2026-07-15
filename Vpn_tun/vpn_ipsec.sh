#!/bin/bash

# Проверка прав root
if [ "$EUID" -ne 0 ]; then
    echo "Этот скрипт требует прав root!"
    echo "Пожалуйста, запустите его через sudo или от имени root"
    exit 1
fi

echo "========================================"
echo "Настройка VPN подключения IT-opt"
echo "========================================"
echo

# Проверка и установка необходимых пакетов
echo "Проверка необходимых пакетов..."
if ! command -v nmcli &> /dev/null; then
    echo "Установка NetworkManager..."
    dnf install -y NetworkManager
fi

if ! rpm -q NetworkManager-l2tp &> /dev/null; then
    echo "Установка NetworkManager-l2tp..."
    dnf install -y NetworkManager-l2tp NetworkManager-l2tp-gnome
fi

# Удаление существующего подключения
echo "Удаление существующего VPN подключения (если есть)..."
nmcli connection delete "IT-opt" 2>/dev/null || true

# Создание VPN подключения
echo "Создание VPN подключения..."
nmcli connection add \
    type vpn \
    vpn-type l2tp \
    con-name "IT-opt" \
    ifname "*" \
    vpn.data "gateway=78.85.28.46,ipsec-enabled=yes,ipsec-psk=JxtymCkj;ysqGfhjkmJnVPN,username=,password-flags=1,ipsec-psk-flags=1" \
    vpn.secrets "ipsec-psk=JxtymCkj;ysqGfhjkmJnVPN" \
    ipv4.dns-search "it-opt.ru" \
    ipv4.never-default yes \
    autoconnect no

# Проверка создания подключения
if [ $? -eq 0 ]; then
    echo "VPN подключение создано успешно!"
else
    echo "Ошибка при создании VPN подключения!"
    exit 1
fi

# Настройка маршрутизации (Split Tunneling)
echo "Настройка маршрутизации..."

# Создаем скрипт для добавления маршрутов при подключении
sudo cat > /etc/NetworkManager/dispatcher.d/99-vpn-routes << 'EOF'
#!/bin/bash
INTERFACE="$1"
ACTION="$2"

# Логируем для отладки
logger -t vpn-routes "INTERFACE=$INTERFACE ACTION=$ACTION"

# Реагируем на поднятие ppp-интерфейса (L2TP) или vpn-up
if [ "$ACTION" = "up" ] && [[ "$INTERFACE" == ppp* ]]; then
    sleep 3
    logger -t vpn-routes "Adding routes for $INTERFACE"
    
    ip route add 192.168.0.1/32 dev "$INTERFACE" 2>/dev/null || true
    ip route add 192.168.0.10/32 dev "$INTERFACE" 2>/dev/null || true
    ip route add 192.168.0.254/32 dev "$INTERFACE" 2>/dev/null || true
    ip route add 10.0.1.10/32 dev "$INTERFACE" 2>/dev/null || true
    ip route add 10.0.1.40/32 dev "$INTERFACE" 2>/dev/null || true
    ip route add 10.0.2.0/24 dev "$INTERFACE" 2>/dev/null || true
fi

# Альтернативное событие vpn-up
if [ "$ACTION" = "vpn-up" ]; then
    sleep 3
    logger -t vpn-routes "VPN-UP event, adding routes via ppp0"
    
    ip route add 192.168.0.1/32 dev ppp0 2>/dev/null || true
    ip route add 192.168.0.10/32 dev ppp0 2>/dev/null || true
    ip route add 192.168.0.254/32 dev ppp0 2>/dev/null || true
    ip route add 10.0.1.10/32 dev ppp0 2>/dev/null || true
    ip route add 10.0.1.40/32 dev ppp0 2>/dev/null || true
    ip route add 10.0.2.0/24 dev ppp0 2>/dev/null || true
fi

# Удаление маршрутов при отключении
if [ "$ACTION" = "down" ] && [[ "$INTERFACE" == ppp* ]]; then
    logger -t vpn-routes "Removing routes for $INTERFACE"
    ip route del 192.168.0.1/32 2>/dev/null || true
    ip route del 192.168.0.10/32 2>/dev/null || true
    ip route del 192.168.0.254/32 2>/dev/null || true
    ip route del 10.0.1.10/32 2>/dev/null || true
    ip route del 10.0.1.40/32 2>/dev/null || true
    ip route del 10.0.2.0/24 2>/dev/null || true
fi
EOF

sudo chmod +x /etc/NetworkManager/dispatcher.d/99-vpn-routes

echo
echo "========================================"
echo "Настройка завершена!"
echo
echo "Для подключения к VPN:"
echo "1. Откройте настройки сети (nm-connection-editor или через GUI)"
echo "2. Найдите подключение 'IT-opt'"
echo "3. Нажмите 'Подключить'"
echo "4. Введите ваш логин и пароль, предоставленные администратором"
echo
echo "Или через командную строку:"
echo "nmcli connection up IT-opt"
echo
echo "Для проверки статуса:"
echo "nmcli connection show IT-opt"
echo "========================================"
