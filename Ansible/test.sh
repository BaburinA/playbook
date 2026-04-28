# ssh-copy-id asn@192.168.29.19
# ssh-copy-id admin1@192.168.32.249 -f
# Отправка ключей на сервера
 ansible -m ping MFC -i host_inv
# ansible -i /etc/ansible/hosts -m shell -a 'uname -a' all

# ansible -i /etc/ansible/hosts -m copy -a 'src=/home/bagik/Ansible/Repos/szi.tar.gz dest=/home/ans' all

