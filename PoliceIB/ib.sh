#!/bin/bash

ansible-playbook -i ./inv/ib ib_fstek_2022_red8.yml --check --limit $1
