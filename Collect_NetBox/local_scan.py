import pynetbox
import socket
import platform
import psutil
import ipaddress
import os

# ==========================================
# 1. СБОР ДАННЫХ О ЛОКАЛЬНОМ LINUX-НОУТБУКЕ
# ==========================================
hostname = socket.gethostname()

def read_sys_file(path):
    try:
        with open(path, 'r', encoding='utf-8', errors='ignore') as f:
            return f.read().strip()
    except Exception:
        return None

serial = read_sys_file('/sys/class/dmi/id/product_serial') or 'Unknown'
manufacturer = read_sys_file('/sys/class/dmi/id/sys_vendor') or 'Unknown'
model = read_sys_file('/sys/class/dmi/id/product_name') or 'Unknown'

print(f"--- Сбор данных о ноутбуке: {hostname} ---")

# ==========================================
# 2. ПОДКЛЮЧЕНИЕ К NETBOX И СОЗДАНИЕ УСТРОЙСТВА
# ==========================================
nb = pynetbox.api('http://10.0.2.17:8000', token='token')
# pattern - nbt_iyqsyD3vZxUB.eSKfKi8mGCYdzUheGKMSwAAC70nplpMAxTNhuk7d-0x11
# Паттерн "Get or Create" для устройства
device = nb.dcim.devices.get(name=hostname)
if not device:
    print(f"Устройство не найдено. Создаем '{hostname}'...")
    device = nb.dcim.devices.create(
        name=hostname,
        role={'slug': 'laptop'},         # <-- Убедитесь, что этот slug есть в NetBox
        site={'slug': 'podval'},         # <-- Убедитесь, что этот slug есть в NetBox
        device_type={'slug': 'generic-laptop'}, # <-- Убедитесь, что этот slug есть в NetBox
        serial=serial,
        comments=f"Модель: {manufacturer} {model}\nОС: {platform.platform()}"
    )
    print(f"✅ Устройство создано (ID: {device.id})")
else:
    print(f"✅ Устройство '{hostname}' уже существует (ID: {device.id})")

# ==========================================
# 3. СБОР И ДОБАВЛЕНИЕ СЕТЕВЫХ ИНТЕРФЕЙСОВ И IP
# ==========================================
print("\n--- Обработка сетевых интерфейсов ---")
interfaces_info = psutil.net_if_addrs()

for iface_name, iface_addresses in interfaces_info.items():
    # Пропускаем loopback (127.0.0.1)
    if iface_name == 'lo':
        continue
        
    # 3.1. Найти или создать интерфейс в NetBox
    nb_iface = nb.dcim.interfaces.get(name=iface_name, device_id=device.id)
    if not nb_iface:
        # Определяем тип интерфейса для NetBox
        # Для Wi-Fi используем ieee802.11n, для остальных (eth, en, wwan) - 1000base-t или virtual
        iface_type = 'ieee802.11n' if ('wlan' in iface_name or iface_name.startswith('wl')) else '1000base-t'
        
        nb_iface = nb.dcim.interfaces.create(
            device=device.id,
            name=iface_name,
            type=iface_type
        )
        print(f"  [+] Создан интерфейс: {iface_name} (тип: {iface_type})")

    # 3.2. Обрабатываем IP-адреса на этом интерфейсе
    for addr in iface_addresses:
        # Нас интересуют только IPv4 адреса
        if addr.family == socket.AF_INET:
            # NetBox требует IP в формате CIDR (например, 192.168.1.5/24).
            # Конвертируем IP и маску сети в этот формат.
            try:
                ip_iface = ipaddress.IPv4Interface(f"{addr.address}/{addr.netmask}")
                ip_cidr = ip_iface.with_prefixlen
            except ValueError:
                continue
                
            # Ищем IP в NetBox
            nb_ip = nb.ipam.ip_addresses.get(address=ip_cidr)
            
            if not nb_ip:
                # Создаем IP и сразу привязываем к интерфейсу
                nb.ipam.ip_addresses.create(
                    address=ip_cidr,
                    assigned_object_type='dcim.interface',
                    assigned_object_id=nb_iface.id,
                    status='active'
                )
                print(f"  [+] Создан IP: {ip_cidr} (привязан к {iface_name})")
            else:
                # Если IP уже существует в NetBox, проверяем, к какому интерфейсу он привязан
                if nb_ip.assigned_object_id != nb_iface.id:
                    nb_ip.assigned_object_type = 'dcim.interface'
                    nb_ip.assigned_object_id = nb_iface.id
                    nb_ip.save()
                    print(f"  [~] IP {ip_cidr} перепривязан на интерфейс {iface_name}")
                else:
                    print(f"  [i] IP {ip_cidr} уже существует и корректно привязан")

print("\n🎉 Сканирование и синхронизация с NetBox завершены!")
