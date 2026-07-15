import pynetbox
import paramiko
import json

# ==========================================
# НАСТРОЙКИ
# ==========================================
NETBOX_URL = 'http://10.0.2.17:8000'
NETBOX_TOKEN = 'nbt_iyqsyD3vZxUB.eSKfKi8mGCYdzUheGKMSwAAC70nplpMAxTNhuk7d'

TARGET_HOSTS = [
    {'host': '192.168.0.244', 'user': 'baburin_ag', 'pass': 'ooM2ufuo022'},
]

NB_SITE = 'podval'
NB_ROLE = 'laptop'
NB_DEV_TYPE = 'generic-laptop'

# ==========================================
# 1. УДАЛЕННЫЙ СБОРЩИК ДАННЫХ (PAYLOAD)
# ==========================================
# ИСПРАВЛЕНО: Добавлены кавычки вокруг путей к файлам
REMOTE_PAYLOAD = """
import socket, json, subprocess, os

def read_f(path):
    try:
        with open(path, 'r', errors='ignore') as f: return f.read().strip()
    except: return 'Unknown'

data = {
    'hostname': socket.gethostname(),
    'serial': read_f('/sys/class/dmi/id/product_serial'),
    'vendor': read_f('/sys/class/dmi/id/sys_vendor'),
    'model': read_f('/sys/class/dmi/id/product_name'),
    'interfaces': []
}

try:
    ip_out = subprocess.check_output(['ip', '-j', 'addr'], stderr=subprocess.DEVNULL).decode()
    data['interfaces'] = json.loads(ip_out)
except Exception:
    pass

print(json.dumps(data))
"""

# ==========================================
# 2. ЛОГИКА ПОДКЛЮЧЕНИЯ К NETBOX
# ==========================================
nb = pynetbox.api(NETBOX_URL, token=NETBOX_TOKEN)

def sync_to_netbox(remote_data):
    hostname = remote_data['hostname']
    print(f"\n--- Обработка {hostname} ---")

    device = nb.dcim.devices.get(name=hostname)
    if not device:
        device = nb.dcim.devices.create(
            name=hostname,
            role={'slug': NB_ROLE},
            site={'slug': NB_SITE},
            device_type={'slug': NB_DEV_TYPE},
            serial=remote_data['serial'],
            comments=f"Модель: {remote_data['vendor']} {remote_data['model']}\nСобрано удаленно."
        )
        print(f"  [+] Устройство создано (ID: {device.id})")
    else:
        print(f"  [i] Устройство найдено (ID: {device.id})")

    for iface in remote_data['interfaces']:
        iface_name = iface.get('ifname')
        if not iface_name or iface_name == 'lo':
            continue

        nb_iface = nb.dcim.interfaces.get(name=iface_name, device_id=device.id)
        if not nb_iface:
            iface_type = 'ieee802.11n' if iface_name.startswith('wl') else '1000base-t'
            nb_iface = nb.dcim.interfaces.create(device=device.id, name=iface_name, type=iface_type)
            print(f"  [+] Интерфейс: {iface_name}")

        for addr_info in iface.get('addr_info', []):
            if addr_info.get('family') == 'inet':
                ip_cidr = f"{addr_info['local']}/{addr_info['prefixlen']}"
                
                nb_ip = nb.ipam.ip_addresses.get(address=ip_cidr)
                if not nb_ip:
                    nb.ipam.ip_addresses.create(
                        address=ip_cidr,
                        assigned_object_type='dcim.interface',
                        assigned_object_id=nb_iface.id,
                        status='active'
                    )
                    print(f"    [+] IP: {ip_cidr}")

# ==========================================
# 3. ГЛАВНЫЙ ЦИКЛ ОПРОСА ПО SSH
# ==========================================
for target in TARGET_HOSTS:
    print(f"\n🔌 Подключение к {target['host']} по SSH...")
    
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        client.connect(target['host'], username=target['user'], password=target['pass'], timeout=5)
        
        # ИСПРАВЛЕНО: Передаем код через stdin, а не через -c
        # Это избавляет от всех проблем с экранированием кавычек
        stdin, stdout, stderr = client.exec_command('python3 -')
        stdin.write(REMOTE_PAYLOAD)
        stdin.channel.shutdown_write()  # Закрываем stdin, чтобы удаленный python знал, что код закончился
        
        output = stdout.read().decode().strip()
        err = stderr.read().decode().strip()
        
        if err and 'WARNING' not in err:
            print(f"  ⚠️ Ошибка на удаленной машине: {err}")
            continue

        remote_data = json.loads(output)
        sync_to_netbox(remote_data)

    except Exception as e:
        print(f"  ❌ Ошибка подключения к {target['host']}: {e}")
    finally:
        client.close()

print("\n🎉 Удаленный опрос завершен!")
