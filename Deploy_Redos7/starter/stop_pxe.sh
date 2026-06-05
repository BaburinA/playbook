#!/bin/bash

sudo systemctl stop httpd
sudo systemctl stop dhcpd
sudo systemctl stop tftp.socket
