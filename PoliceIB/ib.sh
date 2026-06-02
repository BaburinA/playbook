#!/bin/bash

#ansible-playbook -i ./inv/ib ib_fstek_2022_red8.yml --check --limit $1
# ansible-playbook -i ./inv/ib back_up_crit.yml --limit $1
ansible-playbook -i ./inv/ib rollback_police.yml --check --limit $1