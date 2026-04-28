#!/usr/bin/env python3
import json
import requests

url = 'http://192.168.34.101:8080/api_jsonrpc.php'
token = 'bd68a9693bbbf24ea75531ac49241119f2def76293a03506f37c1d8cb151c123'

def get_zabbix_hosts(id=[]):
    return requests.post(
        url,
        json={
            "jsonrpc": "2.0",
            "method": "host.get",
            "params": {
                "groupids": id,
                "output": ["host"],
                "selectInterfaces": ["ip"],
                "filter": {
                    "status": "0"
                },
            },
            "id": 2
        },
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {token}"
        }
    ).json()

# print(json.dumps(get_zabbix_hosts(['50','34']),indent=4,ensure_ascii=False))

def inv_json(id=[]):
    result=get_zabbix_hosts(id)
    hosts = {}
    for i in result['result']:
        hosts[i['interfaces'][0]['ip']] = {}

    return hosts

def inv_ini(id=[]):
    result=get_zabbix_hosts(id)
    hosts=''
    for i in result['result']:
        hosts+=i['host']+' ansible_host='+i['interfaces'][0]['ip']+'\n'

    return hosts

inv = {
    "all": {
        "vars": {
            "ansible_user": "ansible-ib",
            "ansible_ssh_private_key_file": "/home/sitdikov_tr/.ssh/id_rsa"
        }
    },
    "cct": {
        "hosts": inv_json(['50','34'])
    },
    "podryad": {
        "hosts": inv_json('48')
    },
    "buf": {
        "hosts": inv_json('124')
    }
}

print(json.dumps(inv,indent=4,ensure_ascii=False))




