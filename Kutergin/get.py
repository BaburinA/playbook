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
                }
            },
            "id": 2
        },
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {token}"
        }
    ).json()

def get_zabbix_group_id(name=[]):
    return requests.post(
        url,
        json={
            "jsonrpc": "2.0",
            "method": "hostgroup.get",
            "params": {
                "output": ["groupid","name"],
                "filter": {
            "name": name
        }
            },
            "id": 1
        },
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {token}"
        }
    ).json()



print(json.dumps(get_zabbix_group_id(),indent=4,ensure_ascii=False))




