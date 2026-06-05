#!/bin/bash

sudo systemctl enable httpd --now
sudo systemctl enable dhcpd --now
sudo systemctl enable tftp --now
