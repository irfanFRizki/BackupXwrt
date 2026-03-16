#!/bin/sh
# /www/cgi-bin/backupwrt-notify.sh — CGI wrapper
echo "Content-Type: text/plain"
echo "Access-Control-Allow-Origin: *"
echo ""
/usr/bin/backupwrt-notify.sh
