#!/bin/bash

IFACE="wg0" # or "wg", depending on what `ip link` shows

if ip link show "$IFACE" &>/dev/null; then
    echo "UP"
else
    echo "DOWN"
fi
