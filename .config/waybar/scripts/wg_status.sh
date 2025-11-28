#!/usr/bin/env bash

SERVICE_NAME="wg-quick@wg0"

if systemctl is-active --quiet "$SERVICE_NAME"; then
    # icon: pick any VPN/lock icon from Nerd Font
    echo '{"text":"󰖂","class":"connected","alt":"VPN connected"}'
else
    echo '{"text":"󰖂","class":"disconnected","alt":"VPN disconnected"}'
fi
