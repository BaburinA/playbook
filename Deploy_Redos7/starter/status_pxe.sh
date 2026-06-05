#!/bin/bash

systemctl is-active --quiet httpd && echo "OK - HTTPD" || echo "Not OK - HTTPD"
systemctl is-active --quiet dhcpd && echo "OK - DHCPD" || echo "Not OK - DHCPD"
systemctl is-active --quiet tftp && echo "OK - TFTP" || echo "Not OK - TFTP"
exit
