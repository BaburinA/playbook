def server (arg,ip,state=True):
	if state:
		if ip not in arg:
			if arg[-1] == '=':
				return arg+ip
			else:
				return arg+','+ip
	elif not state:
		if ip+',' in arg:
			return arg.replace(ip+',','')
		elif ','+ip in arg:
			return arg.replace(','+ip,'')
		elif ip in arg:
			return arg.replace(ip,'')
	return arg

mass=[
'Server=127.0.0.1,192.168.34.101,192.168.32.100',
'Server=192.168.34.101,127.0.0.1,192.168.32.100',
'Server=192.168.34.101,i18s-a-web1',
'Server=127.0.0.1,i18s-a-web1,192.168.34.101',
'Server=127.0.0.1',
'Server='
]

for i in mass:
	print(server(i,'192.168.34.101'))

