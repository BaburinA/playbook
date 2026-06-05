#!/bin/bash

sudo systemctl disable httpd --now
sudo systemctl disable dhcpd --now
sudo systemctl disable tftp.socket --now
